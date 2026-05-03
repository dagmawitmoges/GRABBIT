-- Grabbit incremental migration — aligns with YOUR baseline schema (generated full_name,
-- order_status enum, vendor_profiles, quantity_remaining, existing vendor_notifications).
-- Run in SQL Editor after the initial Grabbit bootstrap script.
--
-- Adds: locations, vendor_documents, payments, customer notifications, extra order
-- columns, stock trigger. Does NOT drop full_name, duplicate categories, or add a
-- second vendors / vendor_notifications table.

-- ── 0) Stock trigger reset ───────────────────────────────────────────────────
drop trigger if exists trg_orders_apply_deal_quantity on public.orders;
drop function if exists public.apply_order_to_deal_quantity();

-- ── 1) Optional geography (city / country — separate from subcities) ─────────
create table if not exists public.locations (
  id uuid primary key default gen_random_uuid(),
  sub_city varchar(100),
  city varchar(100) not null,
  country varchar(100) not null
);

create index if not exists idx_locations_city on public.locations (city);

-- ── 2) Vendor documents (1:N with vendor_profiles.user_id) ────────────────────
create table if not exists public.vendor_documents (
  id uuid primary key default gen_random_uuid(),
  vendor_user_id uuid not null references public.vendor_profiles (user_id) on delete cascade,
  document_type varchar(50),
  file_url text not null,
  uploaded_at timestamptz not null default now()
);

create index if not exists idx_vendor_documents_vendor on public.vendor_documents (vendor_user_id);

-- ── 3) Orders: order_code, fulfillment hint, total (status stays order_status enum)
alter table public.orders
  add column if not exists order_code text;

alter table public.orders
  add column if not exists preferred_method text default 'pickup';

alter table public.orders
  add column if not exists total_price numeric(12, 2);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'orders_preferred_method_check'
  ) then
    alter table public.orders
      add constraint orders_preferred_method_check check (
        preferred_method is null
        or preferred_method in ('pickup', 'delivery')
      );
  end if;
end $$;

update public.orders
set order_code = claim_code
where order_code is null and claim_code is not null;

update public.orders o
set total_price = coalesce(
  o.total_price,
  (coalesce(o.discounted_price, d.discounted_price, 0)::numeric * coalesce(o.quantity, 1)::numeric)
)
from public.deals d
where o.deal_id = d.id and o.total_price is null;

update public.orders set total_price = 0 where total_price is null;

alter table public.orders
  alter column total_price set default 0;

alter table public.orders
  alter column total_price set not null;

create unique index if not exists uq_orders_order_code
  on public.orders (order_code)
  where order_code is not null;

-- ── 4) Payments ──────────────────────────────────────────────────────────────
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid unique not null references public.orders (id) on delete cascade,
  payment_method varchar(50),
  amount numeric(12, 2) not null,
  status varchar(20) not null default 'pending'
    check (status in ('pending', 'success', 'failed')),
  transaction_reference varchar(255),
  created_at timestamptz not null default now()
);

create index if not exists idx_payments_order on public.payments (order_id);

-- ── 5) Customer notifications (user_id = profiles.id) ─────────────────────
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title varchar(150),
  message text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user on public.notifications (user_id);

-- ── 6) Stock: decrement quantity_remaining; restock on Cancelled ────────────
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

create trigger trg_orders_apply_deal_quantity
  after insert or update of status on public.orders
  for each row
  execute procedure public.apply_order_to_deal_quantity();

-- ── 7) New user → profile (generated full_name from first/last only; + phone/subcity for OTP)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone text;
  v_subcity uuid;
begin
  v_phone := nullif(trim(new.raw_user_meta_data->>'phone'), '');
  begin
    v_subcity := nullif(trim(new.raw_user_meta_data->>'subcity_id'), '')::uuid;
  exception when others then
    v_subcity := null;
  end;

  insert into public.profiles (
    id, email, first_name, last_name, phone, subcity_id, role, is_verified
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'first_name', ''),
    coalesce(new.raw_user_meta_data->>'last_name', ''),
    v_phone,
    v_subcity,
    coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'CUSTOMER'),
    coalesce((new.raw_user_meta_data->>'is_verified')::boolean, false)
  );
  return new;
end;
$$;

-- ── 8) RLS for new tables (same posture as baseline — add policies before prod)
alter table public.locations enable row level security;
alter table public.vendor_documents enable row level security;
alter table public.payments enable row level security;
alter table public.notifications enable row level security;
