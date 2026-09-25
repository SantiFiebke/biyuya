-- Feature flags for user settings. Both features default OFF.
alter table public.user_settings
  alter column debt_settlement_enabled set default false,
  add column if not exists month_projection_enabled boolean not null default false,
  add column if not exists debt_settlement_explainer_seen boolean not null default false,
  add column if not exists month_projection_explainer_seen boolean not null default false;

-- One-time: existing users had debt settlement on by default; turn it off.
update public.user_settings
  set debt_settlement_enabled = false, updated_at = now()
  where debt_settlement_enabled = true;
