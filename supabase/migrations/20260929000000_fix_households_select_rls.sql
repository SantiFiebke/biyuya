-- TASK-002 SECURITY FIX
-- "Households - Select" was USING (true): any authenticated user could read
-- every household, including invite_code (enumeration -> join any household).
--
-- Invite-code lookup for joining now happens ONLY inside the SECURITY DEFINER
-- RPC join_household; clients can no longer SELECT a household by invite_code.

-- join_household was SECURITY INVOKER: it resolves the invite code with a
-- SELECT on public.households, which the tightened policy below would block.
-- Run it as definer so invite-code joining keeps working.
create or replace function public.join_household(
  p_invite_code text
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_household_id bigint;
  v_profile public.profiles;
begin
  if auth.uid() is null then
    raise exception 'join_household: no authenticated user';
  end if;

  if p_invite_code is null or btrim(p_invite_code) = '' then
    raise exception 'join_household: invite code is required';
  end if;

  select id into v_household_id
  from public.households
  where invite_code = upper(btrim(p_invite_code));

  if v_household_id is null then
    return null;
  end if;

  update public.profiles
     set household_id = v_household_id,
         role = 'member'
   where id = auth.uid()
   returning * into v_profile;

  return v_profile;
end;
$$;

-- create_household was SECURITY INVOKER: `insert into households ... returning *`
-- requires the new row to pass the households SELECT policy, but the caller's
-- profiles.household_id is still NULL at that moment -> USING evaluates null
-- -> RETURNING yields no row -> the RPC fails after the policy change below.
-- As definer the insert/returning and the profile/category writes succeed;
-- inputs are still validated (auth.uid() required, name required) and every
-- write targets only the caller's own profile / newly created household.
create or replace function public.create_household(
  p_name text,
  p_categories jsonb default '[]'::jsonb
)
returns public.households
language plpgsql
security definer
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
     set household_id = v_household.id,
         role = 'owner'
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

-- Scope household reads to the caller's own household.
-- invite_code lookup for joining goes through the SECURITY DEFINER RPC
-- join_household, not client SELECT.
-- get_my_household_id() is STABLE and returns the caller's
-- profiles.household_id; a user with no household yields USING null -> zero
-- rows, which is correct (same pattern as expenses/categories policies).
drop policy if exists "Households - Select" on public.households;
create policy "Households - Select" on public.households
  for select to authenticated
  using (id = public.get_my_household_id());

-- ---------------------------------------------------------------------------
-- INTENTIONAL GAPS - do NOT "fix" these by adding policies later:
--
-- * public.households has NO UPDATE and NO DELETE policy. Household mutations
--   are managed via RPCs: leave_household() (member unlinks self) and
--   delete_household() (SECURITY DEFINER, owner-only unlink + delete).
--   Direct client UPDATE/DELETE on households is expected to affect 0 rows.
--
-- * public.profiles has NO DELETE policy. Account deletion is handled by the
--   delete-user Edge Function (service role bypasses RLS).
-- ---------------------------------------------------------------------------