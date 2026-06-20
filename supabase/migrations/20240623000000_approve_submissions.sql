-- Phase 5+: crowdsource submission review → live prices

create or replace function resolve_submission_vendor(p_vendor_name text)
returns uuid
language plpgsql
stable
set search_path = public
as $$
declare
  vendor_id uuid;
  normalized text;
begin
  normalized := lower(trim(p_vendor_name));
  if normalized = '' or normalized is null then
    return null;
  end if;

  select id into vendor_id
  from vendors
  where lower(name) = normalized
  limit 1;

  if vendor_id is not null then
    return vendor_id;
  end if;

  select id into vendor_id
  from vendors
  where lower(name) like '%' || normalized || '%'
     or normalized like '%' || lower(name) || '%'
  order by length(name)
  limit 1;

  return vendor_id;
end;
$$;

create or replace function approve_price_submission(p_submission_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  sub price_submissions%rowtype;
  vendor_id uuid;
begin
  select * into sub
  from price_submissions
  where id = p_submission_id
  for update;

  if not found then
    raise exception 'Submission not found: %', p_submission_id;
  end if;

  if sub.status <> 'pending' then
    raise exception 'Submission % is already %', p_submission_id, sub.status;
  end if;

  if sub.dose_id is null or sub.price is null then
    raise exception 'Submission % missing dose_id or price', p_submission_id;
  end if;

  vendor_id := resolve_submission_vendor(sub.vendor_name);
  if vendor_id is null then
    raise exception 'Could not match vendor name: %', sub.vendor_name;
  end if;

  insert into prices (
    dose_id,
    vendor_id,
    price,
    sale_price,
    discount_code,
    source,
    in_stock,
    last_seen_at
  )
  values (
    sub.dose_id,
    vendor_id,
    sub.price,
    null,
    sub.discount_code,
    'crowdsource',
    true,
    now()
  )
  on conflict (dose_id, vendor_id) do update set
    price = excluded.price,
    discount_code = coalesce(excluded.discount_code, prices.discount_code),
    source = 'crowdsource',
    in_stock = true,
    last_seen_at = now();

  update price_submissions
  set status = 'approved'
  where id = p_submission_id;

  return jsonb_build_object(
    'submission_id', p_submission_id,
    'vendor_id', vendor_id,
    'dose_id', sub.dose_id,
    'status', 'approved'
  );
end;
$$;

create or replace function reject_price_submission(p_submission_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  update price_submissions
  set status = 'rejected'
  where id = p_submission_id
    and status = 'pending';

  if not found then
    raise exception 'Pending submission not found: %', p_submission_id;
  end if;

  return jsonb_build_object('submission_id', p_submission_id, 'status', 'rejected');
end;
$$;

revoke all on function resolve_submission_vendor(text) from public;
revoke all on function approve_price_submission(uuid) from public;
revoke all on function reject_price_submission(uuid) from public;
grant execute on function approve_price_submission(uuid) to service_role;
grant execute on function reject_price_submission(uuid) to service_role;
