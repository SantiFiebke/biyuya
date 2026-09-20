-- Atomic join: resolve invite code and link the authenticated user to that
-- household in a single transaction. Returns null when the code is invalid.
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
     set household_id = v_household_id
   where id = auth.uid()
   returning * into v_profile;

  return v_profile;
end;
$$;

revoke all on function public.join_household(text) from public, anon;
grant execute on function public.join_household(text) to authenticated;
