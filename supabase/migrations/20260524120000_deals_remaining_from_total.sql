-- On create: only quantity_total is needed; remaining starts equal to total and
-- decreases via order trigger. On total change: adjust remaining by the delta.

create or replace function public.deals_sync_remaining_on_insert()
returns trigger
language plpgsql
as $$
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
returns trigger
language plpgsql
as $$
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
