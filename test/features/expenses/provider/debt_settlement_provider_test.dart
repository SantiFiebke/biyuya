import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/provider/household_members_provider.dart';
import 'package:biyuya/src/features/expenses/domain/debt_settlement.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/provider/debt_settlement_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _ana = UserProfile(
  id: 'a',
  name: 'Ana',
  lastName: 'Perez',
  householdId: '1',
);

const _beto = UserProfile(
  id: 'b',
  name: 'Beto',
  lastName: 'Gomez',
  householdId: '1',
);

Expense _expense({
  required double amount,
  required DateTime date,
  required String userUuid,
  int id = 1,
}) {
  return Expense(
    id: id,
    amount: amount,
    date: date,
    householdId: 1,
    categoryId: 1,
    createdAt: date,
    userUuid: userUuid,
  );
}

ProviderContainer _container({
  required List<Expense> expenses,
  required List<UserProfile> members,
}) {
  final container = ProviderContainer(
    overrides: [
      expenseControllerProvider.overrideWithValue(AsyncData(expenses)),
      householdMembersProvider.overrideWithValue(AsyncData(members)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  final expenses = [
    _expense(amount: 800, date: DateTime(2026, 9, 3), userUuid: 'a'),
    _expense(amount: 400, date: DateTime(2026, 9, 12), userUuid: 'b', id: 2),
  ];
  const members = <UserProfile>[_ana, _beto];

  group('debtSettlementProvider', () {
    test('derives transfers from expenseController + householdMembers', () {
      final container = _container(expenses: expenses, members: members);

      final transfers = container.read(
        debtSettlementProvider(year: 2026, month: 9),
      );

      expect(transfers, [
        const DebtTransfer(
          fromUuid: 'b',
          fromName: 'Beto Gomez',
          toUuid: 'a',
          toName: 'Ana Perez',
          amount: 200,
        ),
      ]);
    });

    test('returns empty list for a month with no expenses', () {
      final container = _container(expenses: expenses, members: members);

      final transfers = container.read(
        debtSettlementProvider(year: 2026, month: 1),
      );

      expect(transfers, isEmpty);
    });

    test('returns empty list when household has no members', () {
      final container = _container(expenses: expenses, members: const []);

      final transfers = container.read(
        debtSettlementProvider(year: 2026, month: 9),
      );

      expect(transfers, isEmpty);
    });
  });
}
