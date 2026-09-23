import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/utils/duplicate_detection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Expense expense({
    required int id,
    double amount = 12.5,
    DateTime? date,
    int householdId = 1,
    int categoryId = 7,
    String? description = 'Lunch',
    String? userUuid = 'user-a',
    ExpenseSyncStatus syncStatus = ExpenseSyncStatus.synced,
  }) {
    return Expense(
      id: id,
      amount: amount,
      date: date ?? DateTime(2026, 9, 23),
      householdId: householdId,
      categoryId: categoryId,
      createdAt: DateTime(2026, 9, 23),
      description: description,
      userUuid: userUuid,
      syncStatus: syncStatus,
    );
  }

  group('findDuplicateExpenseIds', () {
    test('(a) two identical -> both ids present', () {
      final result = findDuplicateExpenseIds([expense(id: 1), expense(id: 2)]);
      expect(result, {1, 2});
    });

    test('(b) different description -> empty', () {
      final result = findDuplicateExpenseIds([
        expense(id: 1),
        expense(id: 2, description: 'Dinner'),
      ]);
      expect(result, isEmpty);
    });

    test('(c) different categoryId -> empty', () {
      final result = findDuplicateExpenseIds([
        expense(id: 1),
        expense(id: 2, categoryId: 8),
      ]);
      expect(result, isEmpty);
    });

    test('(d) different day -> empty', () {
      final result = findDuplicateExpenseIds([
        expense(id: 1, date: DateTime(2026, 9, 23)),
        expense(id: 2, date: DateTime(2026, 9, 24)),
      ]);
      expect(result, isEmpty);
    });

    test('(e) different userUuid but same content -> both ids', () {
      final result = findDuplicateExpenseIds([
        expense(id: 1),
        expense(id: 2, userUuid: 'user-b'),
      ]);
      expect(result, {1, 2});
    });

    test('(f) description "Café" vs " café " -> matches', () {
      final result = findDuplicateExpenseIds([
        expense(id: 1, description: 'Café'),
        expense(id: 2, description: ' café '),
      ]);
      expect(result, {1, 2});
    });

    test('(g) three identical -> all 3 ids', () {
      final result = findDuplicateExpenseIds([
        expense(id: 1),
        expense(id: 2),
        expense(id: 3),
      ]);
      expect(result, {1, 2, 3});
    });

    test('(h) different householdId -> empty', () {
      final result = findDuplicateExpenseIds([
        expense(id: 1),
        expense(id: 2, householdId: 2),
      ]);
      expect(result, isEmpty);
    });

    test('(i) one synced + one pending with same content -> both ids', () {
      final result = findDuplicateExpenseIds([
        expense(id: 1),
        expense(id: 2, syncStatus: ExpenseSyncStatus.pending),
      ]);
      expect(result, {1, 2});
    });
  });
}
