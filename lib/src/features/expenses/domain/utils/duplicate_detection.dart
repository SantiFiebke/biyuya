import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';

/// Returns the [Expense.id]s that share identical content with at least one
/// other expense (same household, amount, day, category and description).
///
/// Pure and synchronous: no I/O, no state.
Set<int> findDuplicateExpenseIds(List<Expense> expenses) {
  final buckets = <String, List<Expense>>{};

  for (final expense in expenses) {
    final key =
        '${expense.householdId}|${expense.amount}|'
        '${expense.date.year}-${expense.date.month}-${expense.date.day}|'
        '${expense.categoryId}|'
        '${expense.description?.trim().toLowerCase() ?? ''}';
    buckets.putIfAbsent(key, () => []).add(expense);
  }

  final duplicateIds = <int>{};
  for (final bucket in buckets.values) {
    if (bucket.length > 1) {
      duplicateIds.addAll(bucket.map((e) => e.id));
    }
  }

  return duplicateIds;
}
