-- Reviews tied to completed orders; denormalized vendor for business profile; deal average rating.
-- Run in Supabase SQL Editor after baseline schema (deals, orders, vendor_profiles).

-- Optional: link each deal to the vendor who owns it (nullable).
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

-- Reviews (idempotent: extend existing table if present)
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references public.deals (id) on delete cascade,
  user_id uuid references auth.users (id) on delete set null,
  order_id uuid references public.orders (id) on delete set null,
  vendor_user_id uuid,
  rating integer not null check (rating >= 1 and rating <= 5),
  comment text,
  reviewer_name text,
  created_at timestamptz not null default now()
);

alter table public.reviews add column if not exists deal_id uuid;
alter table public.reviews add column if not exists user_id uuid;
alter table public.reviews add column if not exists order_id uuid;
alter table public.reviews add column if not exists vendor_user_id uuid;
alter table public.reviews add column if not exists rating integer;
alter table public.reviews add column if not exists comment text;
alter table public.reviews add column if not exists reviewer_name text;
alter table public.reviews add column if not exists created_at timestamptz;

-- Backfill NOT NULL deal_id if old table allowed null (adjust if your baseline differs)
-- alter table public.reviews alter column deal_id set not null;

drop index if exists uq_reviews_order_id;
create unique index uq_reviews_order_id
  on public.reviews (order_id)
  where order_id is not null;

create index if not exists idx_reviews_deal on public.reviews (deal_id);
create index if not exists idx_reviews_vendor on public.reviews (vendor_user_id);

-- Copy vendor from deal row on insert
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
  execute function public.reviews_set_vendor_from_deal();

-- Maintain deals.average_rating
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
  execute function public.trg_reviews_refresh_deal_average();

create trigger trg_reviews_avg_upd
  after update of rating, deal_id on public.reviews
  for each row
  execute function public.trg_reviews_refresh_deal_average();

create trigger trg_reviews_avg_del
  after delete on public.reviews
  for each row
  execute function public.trg_reviews_refresh_deal_average();

-- RLS
alter table public.reviews enable row level security;

drop policy if exists "reviews_select_public" on public.reviews;
create policy "reviews_select_public"
  on public.reviews for select
  to anon, authenticated
  using (true);

drop policy if exists "reviews_insert_completed_order" on public.reviews;
create policy "reviews_insert_completed_order"
  on public.reviews for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and order_id is not null
    and exists (
      select 1
      from public.orders o
      where o.id = order_id
        and o.user_id = auth.uid()
        and o.deal_id = deal_id
        and lower(o.status::text) = 'completed'
    )
  );
