-- Phase 5: server-side alert evaluation (called by check-alerts Edge Function)

create or replace function get_alerts_to_fire(debounce_hours int default 24)
returns table (
  alert_id uuid,
  user_id uuid,
  dose_id uuid,
  target_per_mg numeric,
  best_price_per_mg numeric,
  peptide_name text,
  dose_mg numeric
)
language sql
security definer
set search_path = public
stable
as $$
  select
    a.id as alert_id,
    a.user_id,
    a.dose_id,
    a.target_per_mg,
    best.best_price_per_mg,
    p.name as peptide_name,
    d.mg as dose_mg
  from alerts a
  join doses d on d.id = a.dose_id
  join peptides p on p.id = d.peptide_id
  cross join lateral (
    select min(pr.price_per_mg) as best_price_per_mg
    from prices pr
    where pr.dose_id = a.dose_id
      and pr.in_stock = true
  ) best
  where a.active = true
    and best.best_price_per_mg is not null
    and best.best_price_per_mg <= a.target_per_mg
    and (
      a.last_fired_at is null
      or a.last_fired_at < now() - make_interval(hours => debounce_hours)
    );
$$;

create or replace function mark_alerts_fired(alert_ids uuid[])
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count int;
begin
  update alerts
  set last_fired_at = now()
  where id = any(alert_ids);

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

revoke all on function get_alerts_to_fire(int) from public;
revoke all on function mark_alerts_fired(uuid[]) from public;
grant execute on function get_alerts_to_fire(int) to service_role;
grant execute on function mark_alerts_fired(uuid[]) to service_role;
