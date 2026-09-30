import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/expense_merge.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('mergeExpensesByDateDesc', () {
    test('returns one list sorted by date descending', () {
      final synced = [
        makeExpense(date: DateTime(2026, 3, 10)),
        makeExpense(id: 3, date: DateTime(2026, 5)),
      ];
      final pending = [makeExpense(id: 2, date: DateTime(2026, 4, 15))];

      final merged = mergeExpensesByDateDesc(synced, pending);

      expect(merged.map((e) => e.id), [3, 2, 1]);
    });

    test('does not mutate the input lists', () {
      final synced = [
        makeExpense(date: DateTime(2026, 3, 10)),
        makeExpense(id: 3, date: DateTime(2026, 5)),
      ];
      final pending = [makeExpense(id: 2, date: DateTime(2026, 4, 15))];
      final syncedBefore = List<Expense>.of(synced);
      final pendingBefore = List<Expense>.of(pending);

      mergeExpensesByDateDesc(synced, pending);

      expect(synced, syncedBefore);
      expect(pending, pendingBefore);
    });
  });

  group('expensesForMonth', () {
    test('returns only expenses matching year and month', () {
      final expenses = [
        makeExpense(date: DateTime(2026, 8, 31)),
        makeExpense(id: 2, date: DateTime(2026, 9)),
        makeExpense(id: 3, date: DateTime(2026, 9, 30)),
        makeExpense(id: 4, date: DateTime(2026, 10)),
        makeExpense(id: 5, date: DateTime(2025, 9, 15)),
      ];

      final september = expensesForMonth(expenses, 2026, 9);

      expect(september.map((e) => e.id), [2, 3]);
    });

    test('returns empty when no expense matches', () {
      final expenses = [makeExpense(date: DateTime(2026, 8))];

      expect(expensesForMonth(expenses, 2026, 9), isEmpty);
    });
  });
}
