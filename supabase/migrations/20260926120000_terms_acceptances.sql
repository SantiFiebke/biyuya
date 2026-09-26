-- Registro inmutable de aceptación de Términos y Política de Privacidad.
-- El cliente envía accepted_terms/accepted_at/terms_version en signUp(data:);
-- el trigger handle_new_user los copia acá. Sin políticas de INSERT/UPDATE/DELETE
-- para authenticated: el usuario no puede crear, modificar ni borrar su registro.
--
-- Sin backfill para usuarios existentes: nunca aceptaron explícitamente.
-- Si algún día hace falta (solo con consentimiento documentado):
--   insert into public.terms_acceptances (user_id, accepted, accepted_at, terms_version)
--   select id, true, <fecha_de_aceptacion>, '1.0' from auth.users
--   where id not in (select user_id from public.terms_acceptances);

create table if not exists public.terms_acceptances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  accepted boolean not null default true,
  accepted_at timestamptz not null default now(),
  terms_version text not null
);

create index if not exists idx_terms_acceptances_user_id
  on public.terms_acceptances (user_id);

alter table public.terms_acceptances enable row level security;

-- Solo lectura de la propia fila. Sin INSERT/UPDATE/DELETE para authenticated.
drop policy if exists "Terms acceptances - Select own" on public.terms_acceptances;
create policy "Terms acceptances - Select own"
  on public.terms_acceptances
  for select
  to authenticated
  using (user_id = auth.uid());

-- Endurecer privilegios: quitar todo y devolver solo SELECT.
revoke all on table public.terms_acceptances from anon, authenticated;
grant select on table public.terms_acceptances to authenticated;

-- Extender el trigger de alta de usuario para registrar la aceptación.
-- Mismo nombre/firma que la definición original (remote_schema.sql:94-115):
-- CREATE OR REPLACE mantiene el trigger on_auth_user_created vinculado.
create or replace function public.handle_new_user() returns trigger
    language plpgsql security definer
    set search_path to 'public'
    as $$
begin
  insert into public.profiles (
    id, name, last_name, updated_at, household_id
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'first_name', ''),
    coalesce(new.raw_user_meta_data->>'last_name', ''),
    current_date,
    null
  );

  if coalesce((new.raw_user_meta_data->>'accepted_terms')::boolean, false) then
    insert into public.terms_acceptances (user_id, accepted, accepted_at, terms_version)
    values (
      new.id,
      true,
      coalesce((new.raw_user_meta_data->>'accepted_at')::timestamptz, now()),
      coalesce(new.raw_user_meta_data->>'terms_version', '1.0')
    );
  end if;

  return new;
end;
$$;