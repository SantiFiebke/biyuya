import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';

/// Pure helpers for summing only "countable" expenses.
///
/// A category with [Category.isExpense] == false (income/transfer style) makes
/// its expenses non-countable: they are excluded from totals.
/// No Flutter dependencies — safe for domain use and unit tests.

/// Ids of categories that must be excluded from expense totals.
Set<int> excludedCategoryIds(Iterable<Category> categories) {
  return {
    for (final category in categories)
      if (!category.isExpense) category.id,
  };
}

/// Sum of amounts of [expenses] whose categoryId is not excluded.
double sumCountableExpenses(
  Iterable<Expense> expenses,
  Set<int> excludedCategoryIds,
) {
  return expenses.fold(
    0,
    (total, expense) => excludedCategoryIds.contains(expense.categoryId)
        ? total
        : total + expense.amount,
  );
}

/// Convenience: [excludedCategoryIds] derived from [categories] on the fly.
double sumCountableBy(
  Iterable<Expense> expenses,
  Iterable<Category> categories,
) {
  return sumCountableExpenses(expenses, excludedCategoryIds(categories));
}
