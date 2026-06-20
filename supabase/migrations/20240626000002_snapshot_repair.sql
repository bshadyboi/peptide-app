-- Ensure snapshot_prices exists (repair if 20240619000000 was skipped)

create or replace function snapshot_prices()
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_count bigint;
begin
  insert into price_history (dose_id, vendor_id, price, price_per_mg, captured_at)
  select
    dose_id,
    vendor_id,
    coalesce(sale_price, price),
    price_per_mg,
    now()
  from prices
  where exists (
    select 1 from vendors v
    where v.id = prices.vendor_id and v.is_active = true
  );

  get diagnostics inserted_count = row_count;
  return inserted_count;
end;
$$;

revoke all on function snapshot_prices() from public;
grant execute on function snapshot_prices() to service_role;
