-- Ownership model: role on profiles + one owner per household.
alter table public.profiles
  add column role text not null default 'member'
  check (role in ('owner', 'member'));

create unique index profiles_one_owner_per_household
  on public.profiles (household_id)
  where role = 'owner' and household_id is not null;

-- create_household: creator becomes owner.
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

-- join_household: joiner becomes member.
create or replace function public.join_household(
  p_invite_code text
)
returns public.profiles
language plpgsql
security invoker
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

-- leave_household: members only. Owner must delete the household.
create or replace function public.leave_household()
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_role text;
  v_household_id bigint;
begin
  if auth.uid() is null then
    raise exception 'leave_household: no authenticated user';
  end if;

  select role, household_id into v_role, v_household_id
  from public.profiles where id = auth.uid();

  if v_household_id is null then
    raise exception 'leave_household: not in a household';
  end if;

  if v_role = 'owner' then
    raise exception 'leave_household: owner must delete the household';
  end if;

  update public.profiles set household_id = null where id = auth.uid();
end;
$$;

-- delete_household: owner only. Unlinks all members, then deletes the
-- household (cascade removes categories and expenses).
create or replace function public.delete_household()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_household_id bigint;
begin
  if auth.uid() is null then
    raise exception 'delete_household: no authenticated user';
  end if;

  select role, household_id into v_role, v_household_id
  from public.profiles where id = auth.uid();

  if v_household_id is null then
    raise exception 'delete_household: not in a household';
  end if;

  if v_role <> 'owner' then
    raise exception 'delete_household: only the owner can delete the household';
  end if;

  update public.profiles
     set household_id = null, role = 'member'
   where household_id = v_household_id;

  delete from public.households where id = v_household_id;
end;
$$;

revoke all on function public.leave_household() from public, anon;
grant execute on function public.leave_household() to authenticated;

revoke all on function public.delete_household() from public, anon;
grant execute on function public.delete_household() to authenticated;
