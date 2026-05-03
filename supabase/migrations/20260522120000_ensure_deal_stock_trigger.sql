-- Idempotent: (re)install stock trigger if it was never applied or was dropped.
-- Decrements deals.quantity_remaining on order insert; restocks on Cancelled.

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
