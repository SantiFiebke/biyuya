-- Atomic household creation: insert household, link the authenticated user,
-- and seed default categories (passed from the app) in a single transaction.
create or replace function public.create_household(
  p_name text,
  p_categories jsonb default '[]'::jsonb
)
returns public.households
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_household public.households;
begin
  if auth.uid() is null then
    raise exception 'create_household: no authenticated user';
  end if;

  if p_name is null or btrim(p_name) = '' then
    raise exception 'create_household: name is required';
  end if;

  insert into public.households (name)
  values (btrim(p_name))
  returning * into v_household;

  update public.profiles
     set household_id = v_household.id
   where id = auth.uid();

  insert into public.categories (name, color, icon, household_id)
  select
    c->>'name',
    c->>'color',
    c->>'icon',
    v_household.id
  from jsonb_array_elements(coalesce(p_categories, '[]'::jsonb)) as c
  where coalesce(c->>'name', '') <> '';

  return v_household;
end;
$$;

revoke all on function public.create_household(text, jsonb) from public, anon;
grant execute on function public.create_household(text, jsonb) to authenticated;
