-- profiles: listing household members + RLS household checks filter by household_id.
create index if not exists idx_profiles_household_id
  on public.profiles (household_id);