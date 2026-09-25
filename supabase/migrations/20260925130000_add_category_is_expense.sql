-- Adds a flag to categories to exclude non-expense categories (e.g. Ahorro) from expense totals.
alter table public.categories
  add column if not exists is_expense boolean not null default true;

-- One-time data fix for the imported household: Ahorro is savings, not an expense.
update public.categories
  set is_expense = false, last_modified_at = now()
  where household_id = 2 and name = 'Ahorro';
