-- Let customers record a payment row for their own order (after order insert).

alter table public.payments enable row level security;

drop policy if exists "payments_select_own_order" on public.payments;
drop policy if exists "payments_insert_own_order" on public.payments;

create policy "payments_select_own_order"
  on public.payments for select
  to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = payments.order_id and o.user_id = auth.uid()
    )
  );

create policy "payments_insert_own_order"
  on public.payments for insert
  to authenticated
  with check (
    exists (
      select 1 from public.orders o
      where o.id = payments.order_id and o.user_id = auth.uid()
    )
  );
