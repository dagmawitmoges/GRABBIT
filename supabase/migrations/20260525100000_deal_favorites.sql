-- Per-user saved deals (favorites). Run in Supabase SQL Editor if not using CLI migrate.

create table if not exists public.deal_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  deal_id uuid not null references public.deals (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, deal_id)
);

create index if not exists idx_deal_favorites_user
  on public.deal_favorites (user_id);

create index if not exists idx_deal_favorites_deal
  on public.deal_favorites (deal_id);

alter table public.deal_favorites enable row level security;

drop policy if exists "deal_favorites_select_own" on public.deal_favorites;
drop policy if exists "deal_favorites_insert_own" on public.deal_favorites;
drop policy if exists "deal_favorites_delete_own" on public.deal_favorites;

create policy "deal_favorites_select_own"
  on public.deal_favorites for select
  to authenticated
  using (user_id = auth.uid());

create policy "deal_favorites_insert_own"
  on public.deal_favorites for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "deal_favorites_delete_own"
  on public.deal_favorites for delete
  to authenticated
  using (user_id = auth.uid());
