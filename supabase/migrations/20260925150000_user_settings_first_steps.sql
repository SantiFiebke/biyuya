-- Dismissal flag for the Home "Primeros pasos" checklist.
alter table public.user_settings
  add column if not exists first_steps_dismissed boolean not null default false;
