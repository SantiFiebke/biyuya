import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/services/featured_categories_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Expense _expense({
  required int categoryId,
  required DateTime date,
  int id = 0,
}) {
  return Expense(
    id: id,
    amount: 10,
    date: date,
    householdId: 1,
    categoryId: categoryId,
    createdAt: date,
  );
}

void main() {
  final now = DateTime(2026, 9, 23, 12);

  group('topCategoryIdsLastWeek', () {
    test('counts occurrences per category and orders by frequency DESC', () {
      final expenses = [
        _expense(categoryId: 7, date: now),
        _expense(categoryId: 7, date: now),
        _expense(categoryId: 7, date: now),
        _expense(categoryId: 3, date: now),
        _expense(categoryId: 3, date: now),
        _expense(categoryId: 9, date: now),
      ];

      expect(topCategoryIdsLastWeek(expenses, now), [7, 3, 9]);
    });

    test('respects limit when more categories than limit', () {
      final expenses = [
        _expense(categoryId: 1, date: now),
        _expense(categoryId: 1, date: now),
        _expense(categoryId: 1, date: now),
        _expense(categoryId: 2, date: now),
        _expense(categoryId: 2, date: now),
        _expense(categoryId: 3, date: now),
        _expense(categoryId: 4, date: now),
      ];

      expect(topCategoryIdsLastWeek(expenses, now, limit: 2), [1, 2]);
    });

    test('ignores expenses outside the inclusive 7-day window', () {
      final windowStart = now.subtract(const Duration(days: 7));
      final expenses = [
        _expense(categoryId: 1, date: windowStart), // inclusive lower bound
        _expense(categoryId: 1, date: now), // inclusive upper bound
        _expense(
          categoryId: 2,
          date: windowStart.subtract(const Duration(milliseconds: 1)),
        ), // just before window
        _expense(
          categoryId: 3,
          date: now.add(const Duration(milliseconds: 1)),
        ), // just after window
      ];

      expect(topCategoryIdsLastWeek(expenses, now), [1]);
    });

    test('empty list returns empty result', () {
      expect(topCategoryIdsLastWeek(const [], now), isEmpty);
    });

    test('tie on count breaks by most recent expense date DESC', () {
      final expenses = [
        // Category 5: two expenses, most recent = yesterday.
        _expense(categoryId: 5, date: now.subtract(const Duration(days: 1))),
        _expense(categoryId: 5, date: now.subtract(const Duration(days: 6))),
        // Category 6: two expenses, most recent = now.
        _expense(categoryId: 6, date: now),
        _expense(categoryId: 6, date: now.subtract(const Duration(days: 5))),
      ];

      expect(topCategoryIdsLastWeek(expenses, now), [6, 5]);
    });

    test('tie on count and date breaks by id ASC', () {
      final expenses = [
        _expense(categoryId: 42, date: now),
        _expense(categoryId: 7, date: now),
      ];

      expect(topCategoryIdsLastWeek(expenses, now), [7, 42]);
    });
  });
}
