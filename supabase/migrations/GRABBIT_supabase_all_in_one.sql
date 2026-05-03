-- ============================================================================
-- GRABBIT — one-shot Supabase SQL (SQL Editor: paste & run as a single script)
-- Safe to re-run: uses IF NOT EXISTS / DROP POLICY IF EXISTS / OR REPLACE where possible.
-- ============================================================================

-- ── 0) deal_favorites: table + unique pair + indexes + RLS ──────────────────
create table if not exists public.deal_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  deal_id uuid not null references public.deals (id) on delete cascade,
  created_at timestamptz not null default now()
);

do $$
begin
  alter table public.deal_favorites
    add constraint deal_favorites_user_deal_key unique (user_id, deal_id);
exception
  when duplicate_object then null;
end $$;

create index if not exists idx_deal_favorites_user on public.deal_favorites (user_id);
create index if not exists idx_deal_favorites_deal on public.deal_favorites (deal_id);

alter table public.deal_favorites enable row level security;

drop policy if exists "deal_favorites_select_own" on public.deal_favorites;
drop policy if exists "deal_favorites_insert_own" on public.deal_favorites;
drop policy if exists "deal_favorites_delete_own" on public.deal_favorites;

create policy "deal_favorites_select_own"
  on public.deal_favorites for select to authenticated
  using (user_id = auth.uid());

create policy "deal_favorites_insert_own"
  on public.deal_favorites for insert to authenticated
  with check (user_id = auth.uid());

create policy "deal_favorites_delete_own"
  on public.deal_favorites for delete to authenticated
  using (user_id = auth.uid());

-- ── 1) locations: public read (signup / filters) ───────────────────────────
alter table public.locations enable row level security;

drop policy if exists "locations_select_public" on public.locations;
create policy "locations_select_public"
  on public.locations for select to anon, authenticated
  using (true);

-- ── 2) notifications: own rows only ───────────────────────────────────────
alter table public.notifications enable row level security;

drop policy if exists "notifications_select_own" on public.notifications;
drop policy if exists "notifications_insert_own" on public.notifications;
drop policy if exists "notifications_update_own" on public.notifications;

create policy "notifications_select_own"
  on public.notifications for select to authenticated
  using (user_id = auth.uid());

create policy "notifications_insert_own"
  on public.notifications for insert to authenticated
  with check (user_id = auth.uid());

create policy "notifications_update_own"
  on public.notifications for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ── 3) payments: own order only ────────────────────────────────────────────
alter table public.payments enable row level security;

drop policy if exists "payments_select_own_order" on public.payments;
drop policy if exists "payments_insert_own_order" on public.payments;

create policy "payments_select_own_order"
  on public.payments for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = payments.order_id and o.user_id = auth.uid()
    )
  );

create policy "payments_insert_own_order"
  on public.payments for insert to authenticated
  with check (
    exists (
      select 1 from public.orders o
      where o.id = payments.order_id and o.user_id = auth.uid()
    )
  );

-- ── 4) deals: columns for ratings / vendor link (if missing) ───────────────
alter table public.deals add column if not exists vendor_user_id uuid;
alter table public.deals add column if not exists average_rating numeric(5, 2);

do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'vendor_profiles'
  ) and not exists (
    select 1 from pg_constraint where conname = 'deals_vendor_user_id_fkey'
  ) then
    alter table public.deals
      add constraint deals_vendor_user_id_fkey
      foreign key (vendor_user_id) references public.vendor_profiles (user_id)
      on delete set null;
  end if;
exception
  when duplicate_object then null;
  when undefined_table then null;
end $$;

-- ── 5) deals: quantity_remaining sync (new deals / total changes) ───────────
create or replace function public.deals_sync_remaining_on_insert()
returns trigger language plpgsql as $$
begin
  new.quantity_remaining := coalesce(new.quantity_total, 0);
  return new;
end;
$$;

drop trigger if exists trg_deals_sync_remaining_on_insert on public.deals;
create trigger trg_deals_sync_remaining_on_insert
  before insert on public.deals
  for each row
  execute procedure public.deals_sync_remaining_on_insert();

create or replace function public.deals_adjust_remaining_when_total_changes()
returns trigger language plpgsql as $$
declare
  delta int;
begin
  if new.quantity_total is distinct from old.quantity_total then
    delta := coalesce(new.quantity_total, 0) - coalesce(old.quantity_total, 0);
    new.quantity_remaining := greatest(0, coalesce(old.quantity_remaining, 0) + delta);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_deals_adjust_remaining_on_total on public.deals;
create trigger trg_deals_adjust_remaining_on_total
  before update of quantity_total on public.deals
  for each row
  execute procedure public.deals_adjust_remaining_when_total_changes();

-- ── 6) orders: stock trigger (requires order_status enum + Cancelled) ─────
create or replace function public.apply_order_to_deal_quantity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count int;
begin
  if tg_op = 'insert' then
    if new.status = 'Cancelled'::public.order_status then
      return new;
    end if;
    update public.deals
    set quantity_remaining = quantity_remaining - new.quantity
    where id = new.deal_id
      and quantity_remaining >= new.quantity;

    get diagnostics updated_count = row_count;
    if updated_count = 0 then
      raise exception 'Not enough quantity available for this deal.';
    end if;
    return new;
  end if;

  if tg_op = 'update' then
    if old.status is distinct from 'Cancelled'::public.order_status
       and new.status = 'Cancelled'::public.order_status then
      update public.deals
      set quantity_remaining = quantity_remaining + old.quantity
      where id = old.deal_id;
    end if;
    return new;
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_orders_apply_deal_quantity on public.orders;
create trigger trg_orders_apply_deal_quantity
  after insert or update of status on public.orders
  for each row
  execute procedure public.apply_order_to_deal_quantity();

-- ── 7) reviews: indexes + vendor copy + average_rating + RLS ───────────────
-- (Your schema already defines public.reviews; we only add helpers.)

create index if not exists idx_reviews_deal on public.reviews (deal_id);
create index if not exists idx_reviews_vendor on public.reviews (vendor_user_id);

create or replace function public.reviews_set_vendor_from_deal()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  select d.vendor_user_id into new.vendor_user_id
  from public.deals d
  where d.id = new.deal_id;
  return new;
end;
$$;

drop trigger if exists trg_reviews_set_vendor on public.reviews;
create trigger trg_reviews_set_vendor
  before insert on public.reviews
  for each row
  execute procedure public.reviews_set_vendor_from_deal();

create or replace function public.trg_reviews_refresh_deal_average()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_deal uuid;
begin
  if tg_op = 'DELETE' then
    target_deal := old.deal_id;
  else
    target_deal := new.deal_id;
  end if;

  update public.deals
  set average_rating = (
    select round(avg(rating)::numeric, 2)
    from public.reviews
    where deal_id = target_deal
  )
  where id = target_deal;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_reviews_avg_ins on public.reviews;
drop trigger if exists trg_reviews_avg_upd on public.reviews;
drop trigger if exists trg_reviews_avg_del on public.reviews;

create trigger trg_reviews_avg_ins
  after insert on public.reviews
  for each row
  execute procedure public.trg_reviews_refresh_deal_average();

create trigger trg_reviews_avg_upd
  after update of rating, deal_id on public.reviews
  for each row
  execute procedure public.trg_reviews_refresh_deal_average();

create trigger trg_reviews_avg_del
  after delete on public.reviews
  for each row
  execute procedure public.trg_reviews_refresh_deal_average();

alter table public.reviews enable row level security;

drop policy if exists "reviews_select_public" on public.reviews;
create policy "reviews_select_public"
  on public.reviews for select to anon, authenticated
  using (true);

drop policy if exists "reviews_insert_completed_order" on public.reviews;
create policy "reviews_insert_completed_order"
  on public.reviews for insert to authenticated
  with check (
    user_id = auth.uid()
    and order_id is not null
    and exists (
      select 1 from public.orders o
      where o.id = order_id
        and o.user_id = auth.uid()
        and o.deal_id = deal_id
        and lower(o.status::text) = 'completed'
    )
  );

-- ============================================================================
-- Done. If something errors:
--   - order_status must include Created, Completed, Cancelled (exact labels).
--   - If triggers fail on PG15+, try: execute function ... instead of procedure
--     (Supabase usually accepts execute procedure for trigger functions).
-- ============================================================================
