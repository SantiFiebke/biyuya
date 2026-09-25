import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/domain/models/category_model.dart';
import 'package:biyuya/src/features/expenses/domain/debt_settlement.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/expense_totals.dart';
import 'package:flutter_test/flutter_test.dart';

final _createdAt = DateTime(2025);

final _groceries = Category(
  id: 1,
  name: 'Groceries',
  householdId: 42,
  createdAt: _createdAt,
);

final _transport = Category(
  id: 2,
  name: 'Transport',
  householdId: 42,
  createdAt: _createdAt,
);

final _ahorro = Category(
  id: 99,
  name: 'Ahorro',
  householdId: 42,
  createdAt: _createdAt,
  isExpense: false,
);

Expense _expense({
  required int id,
  required double amount,
  required int categoryId,
  String? userUuid,
  DateTime? date,
}) {
  final d = date ?? DateTime(2026, 9, 10);
  return Expense(
    id: id,
    amount: amount,
    date: d,
    householdId: 42,
    categoryId: categoryId,
    createdAt: d,
    userUuid: userUuid,
  );
}

const _ana = UserProfile(id: 'a', name: 'Ana', lastName: 'Perez');
const _beto = UserProfile(id: 'b', name: 'Beto', lastName: 'Gomez');

void main() {
  group('excludedCategoryIds', () {
    test('collects only categories with isExpense=false', () {
      final ids = excludedCategoryIds([
        _groceries,
        _transport,
        _ahorro,
        Category(
          id: 5,
          name: 'Salary',
          householdId: 42,
          createdAt: _createdAt,
          isExpense: false,
        ),
      ]);

      expect(ids, {99, 5});
    });

    test('default isExpense=true is never excluded', () {
      // No isExpense argument -> defaults to true.
      expect(excludedCategoryIds([_groceries, _transport]), isEmpty);
    });
  });

  group('sumCountableExpenses', () {
    test('sums only expenses outside the excluded set', () {
      final expenses = [
        _expense(id: 1, amount: 100, categoryId: 1),
        _expense(id: 2, amount: 50, categoryId: 2),
        _expense(id: 3, amount: 999, categoryId: 99),
        _expense(id: 4, amount: 25.5, categoryId: 1),
      ];

      expect(sumCountableExpenses(expenses, {99}), 175.5);
      // Without exclusion everything counts.
      expect(sumCountableExpenses(expenses, const {}), 1174.5);
    });
  });

  group('sumCountableBy', () {
    test('excludes Ahorro amounts when categories passed directly', () {
      final expenses = [
        _expense(id: 1, amount: 100, categoryId: 1),
        _expense(id: 2, amount: 500, categoryId: 99),
        _expense(id: 3, amount: 40, categoryId: 2),
      ];

      expect(sumCountableBy(expenses, [_groceries, _transport, _ahorro]), 140);
    });
  });

  group('CategoryModel.is_expense', () {
    final baseJson = <String, dynamic>{
      'id': 7,
      'name': 'Ahorro',
      'color': null,
      'icon': null,
      'household_id': 42,
      'created_at': '2025-01-01T00:00:00.000Z',
    };

    test('is_expense=false -> isExpense false', () {
      final model = CategoryModel.fromJson({...baseJson, 'is_expense': false});
      expect(model.isExpense, isFalse);
    });

    test('missing is_expense defaults to true', () {
      final model = CategoryModel.fromJson(baseJson);
      expect(model.isExpense, isTrue);
    });

    test('round-trip via toJson preserves isExpense', () {
      for (final value in [true, false]) {
        final model = CategoryModel.fromJson({
          ...baseJson,
          'is_expense': value,
        });

        final json = model.toJson();
        expect(json['is_expense'], value);

        // toJson omits server-generated id/created_at; re-add for fromJson.
        final roundTripped = CategoryModel.fromJson({
          ...json,
          'id': model.id,
          'created_at': '2025-01-01T00:00:00.000Z',
        });
        expect(roundTripped.isExpense, value);
      }
    });
  });

  group('settleDebts excludedCategoryIds', () {
    test('Ahorro expense not counted in balances/total', () {
      final expenses = [
        _expense(id: 1, amount: 100, categoryId: 1, userUuid: 'a'),
        _expense(id: 2, amount: 500, categoryId: 99, userUuid: 'a'),
      ];
      const members = [_ana, _beto];

      final withExclusion = settleDebts(
        expenses: expenses,
        members: members,
        year: 2026,
        month: 9,
        excludedCategoryIds: {99},
      );
      final withoutExclusion = settleDebts(
        expenses: expenses,
        members: members,
        year: 2026,
        month: 9,
      );

      // Excluded: pot 100, share 50, Beto owes Ana 50.
      expect(withExclusion, [
        const DebtTransfer(
          fromUuid: 'b',
          fromName: 'Beto Gomez',
          toUuid: 'a',
          toName: 'Ana Perez',
          amount: 50,
        ),
      ]);

      // Not excluded: pot 600, share 300, Beto owes Ana 300.
      expect(withoutExclusion, [
        const DebtTransfer(
          fromUuid: 'b',
          fromName: 'Beto Gomez',
          toUuid: 'a',
          toName: 'Ana Perez',
          amount: 300,
        ),
      ]);
    });
  });
}
