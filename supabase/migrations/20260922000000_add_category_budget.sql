-- Presupuesto por categoría: monto opcional (nullable) y positivo.
-- numeric(10, 2) igual que expenses.amount.
alter table public.categories
  add column budget_amount numeric(10, 2);

alter table public.categories
  add constraint categories_budget_amount_positive
  check (budget_amount is null or budget_amount > 0);
