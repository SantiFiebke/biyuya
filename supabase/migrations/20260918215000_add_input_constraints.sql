-- Input constraints (item 1: validación de formularios).
-- La DB estaba vacía (reset), así que no hay datos que violen estas reglas.

-- Monto: hasta 8 dígitos enteros + 2 decimales, siempre positivo.
alter table public.expenses
  alter column amount type numeric(10, 2);

alter table public.expenses
  add constraint expenses_amount_positive check (amount > 0);

-- Descripción opcional, máximo 200 caracteres.
alter table public.expenses
  add constraint expenses_description_length
  check (description is null or char_length(description) <= 200);

-- Nombre de categoría: 1..50 (sin espacios alrededor).
alter table public.categories
  add constraint categories_name_length
  check (char_length(btrim(name)) between 1 and 50);

-- Nombre de hogar: 1..100.
alter table public.households
  add constraint households_name_length
  check (char_length(btrim(name)) between 1 and 100);

-- Nombre y apellido de perfil: máximo 200 (permitido vacío, el trigger puede insertar '').
alter table public.profiles
  add constraint profiles_name_length check (char_length(name) <= 200);

alter table public.profiles
  add constraint profiles_last_name_length check (char_length(last_name) <= 200);
