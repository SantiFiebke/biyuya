-- Performance indexes for hot query paths.
-- expenses: filter by household_id + date range/order (getExpenses, getExpensesByMonth, reports, RLS).
create index if not exists idx_expenses_household_date
  on public.expenses (household_id, date);

-- expenses: FK expenses.category_id (ON DELETE RESTRICT) — evita seq scan al borrar categorías.
create index if not exists idx_expenses_category_id
  on public.expenses (category_id);

-- expenses: FK expenses.user_uuid (ON DELETE SET NULL) — account deletion.
create index if not exists idx_expenses_user_uuid
  on public.expenses (user_uuid);

-- categories: filter by household_id + order by name.
create index if not exists idx_categories_household_name
  on public.categories (household_id, name);
