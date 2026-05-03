-- Replace subcities with locations: copy rows (same id), repoint FKs, drop subcities.
-- Default city/country for migrated rows — adjust seed data in SQL if needed.

-- ── 0) locations.sort_order (for dropdown ordering like subcities) ─────────
alter table public.locations
  add column if not exists sort_order int not null default 0;

-- ── 1) Copy subcities → locations (preserve id so FK updates are simple) ────
insert into public.locations (id, sub_city, city, country, sort_order)
select
  s.id,
  s.name::varchar(100),
  'Addis Ababa'::varchar(100),
  'Ethiopia'::varchar(100),
  s.sort_order
from public.subcities s
on conflict (id) do update set
  sub_city = excluded.sub_city,
  sort_order = excluded.sort_order;

-- ── 2) Drop every FK that points at subcities ───────────────────────────────
do $$
declare
  r record;
begin
  for r in
    select c.conrelid::regclass as tbl, c.conname as cname
    from pg_constraint c
    where c.confrelid = 'public.subcities'::regclass
      and c.contype = 'f'
  loop
    execute format('alter table %s drop constraint %I', r.tbl, r.cname);
  end loop;
end $$;

-- ── 3) deals: one location column (merge legacy subcity_id + location_id) ────
update public.deals d
set subcity_id = coalesce(d.location_id, d.subcity_id);

alter table public.deals
  drop column if exists location_id;

alter table public.deals
  rename column subcity_id to location_id;

alter table public.deals
  alter column location_id set not null;

alter table public.deals
  add constraint deals_location_id_fkey
  foreign key (location_id) references public.locations (id) on delete restrict;

-- ── 4) profiles: subcity_id → location_id ───────────────────────────────────
alter table public.profiles
  rename column subcity_id to location_id;

alter table public.profiles
  add constraint profiles_location_id_fkey
  foreign key (location_id) references public.locations (id) on delete set null;

-- ── 5) vendor_branches ──────────────────────────────────────────────────────
alter table public.vendor_branches
  rename column subcity_id to location_id;

alter table public.vendor_branches
  add constraint vendor_branches_location_id_fkey
  foreign key (location_id) references public.locations (id) on delete restrict;

create index if not exists idx_vendor_branches_location on public.vendor_branches (location_id);

-- ── 6) Indexes on deals ──────────────────────────────────────────────────────
drop index if exists idx_deals_subcity;
create index if not exists idx_deals_location on public.deals (location_id);

-- ── 7) Drop subcities ───────────────────────────────────────────────────────
drop table if exists public.subcities;

-- ── 8) Auth trigger: metadata location_id (fallback subcity_id for old clients)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone text;
  v_location uuid;
  v_raw text;
begin
  v_phone := nullif(trim(new.raw_user_meta_data->>'phone'), '');
  v_raw := coalesce(
    nullif(trim(new.raw_user_meta_data->>'location_id'), ''),
    nullif(trim(new.raw_user_meta_data->>'subcity_id'), '')
  );
  begin
    v_location := v_raw::uuid;
  exception when others then
    v_location := null;
  end;

  insert into public.profiles (
    id, email, first_name, last_name, phone, location_id, role, is_verified
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'first_name', ''),
    coalesce(new.raw_user_meta_data->>'last_name', ''),
    v_phone,
    v_location,
    coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'CUSTOMER'),
    coalesce((new.raw_user_meta_data->>'is_verified')::boolean, false)
  );
  return new;
end;
$$;
