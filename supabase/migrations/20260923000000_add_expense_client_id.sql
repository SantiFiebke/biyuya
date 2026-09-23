-- client_id generado por el cliente para sync offline idempotente.
-- Postgres UNIQUE permite múltiples NULL, así que las filas legacy siguen válidas.
-- La constraint es requerida para el upsert de Supabase (onConflict: 'client_id').
alter table public.expenses
  add column client_id uuid;

alter table public.expenses
  add constraint expenses_client_id_key unique (client_id);