import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/expenses/domain/debt_settlement.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
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

const _caro = UserProfile(
  id: 'c',
  name: 'Caro',
  lastName: 'Ruiz',
  householdId: '1',
);

Expense _expense({
  required double amount,
  required DateTime date,
  String? userUuid,
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

/// Net flow for [uuid]: incoming minus outgoing across all transfers.
double _netFor(List<DebtTransfer> transfers, String uuid) {
  var incoming = 0.0;
  var outgoing = 0.0;
  for (final transfer in transfers) {
    if (transfer.toUuid == uuid) {
      incoming += transfer.amount;
    }
    if (transfer.fromUuid == uuid) {
      outgoing += transfer.amount;
    }
  }
  return incoming - outgoing;
}

void main() {
  final september = DateTime(2026, 9);

  group('settleDebts', () {
    test('member who paid everything is credited an equal share', () {
      // Total 3000, 3 members -> share 1000 each. Ana paid all.
      final expenses = [
        _expense(amount: 1000, date: DateTime(2026, 9, 5), userUuid: 'a'),
        _expense(amount: 1000, date: DateTime(2026, 9, 12), userUuid: 'a'),
        _expense(amount: 1000, date: DateTime(2026, 9, 20), userUuid: 'a'),
      ];

      final transfers = settleDebts(
        expenses: expenses,
        members: const [_ana, _beto, _caro],
        year: 2026,
        month: 9,
      );

      expect(
        transfers,
        unorderedEquals([
          const DebtTransfer(
            fromUuid: 'b',
            fromName: 'Beto Gomez',
            toUuid: 'a',
            toName: 'Ana Perez',
            amount: 1000,
          ),
          const DebtTransfer(
            fromUuid: 'c',
            fromName: 'Caro Ruiz',
            toUuid: 'a',
            toName: 'Ana Perez',
            amount: 1000,
          ),
        ]),
      );
    });

    test('settles the difference when both members paid', () {
      // Total 1200, 2 members -> share 600. Beto owes Ana 200.
      final expenses = [
        _expense(amount: 800, date: september, userUuid: 'a'),
        _expense(amount: 400, date: september, userUuid: 'b'),
      ];

      final transfers = settleDebts(
        expenses: expenses,
        members: const [_ana, _beto],
        year: 2026,
        month: 9,
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

    test('returns empty list when household is balanced', () {
      final expenses = [
        _expense(amount: 600, date: september, userUuid: 'a'),
        _expense(amount: 600, date: september, userUuid: 'b'),
      ];

      final transfers = settleDebts(
        expenses: expenses,
        members: const [_ana, _beto],
        year: 2026,
        month: 9,
      );

      expect(transfers, isEmpty);
    });

    test('excludes expenses without payer from the pot', () {
      // Pot = 100 (null-payer 500 ignored) -> share 50 each.
      final expenses = [
        _expense(amount: 100, date: september, userUuid: 'a'),
        _expense(amount: 500, date: september),
      ];

      final transfers = settleDebts(
        expenses: expenses,
        members: const [_ana, _beto],
        year: 2026,
        month: 9,
      );

      expect(transfers, [
        const DebtTransfer(
          fromUuid: 'b',
          fromName: 'Beto Gomez',
          toUuid: 'a',
          toName: 'Ana Perez',
          amount: 50,
        ),
      ]);

      // Expected balances (paid - share) still sum to zero.
      const expected = {'a': 50.0, 'b': -50.0};
      final total = expected.values.fold<double>(0, (sum, v) => sum + v);
      expect(total, closeTo(0, 1e-9));
    });

    test('conservation invariant holds for every member', () {
      // Awkward thirds: share = 355.85 / 3 -> non-cent balances.
      final expenses = [
        _expense(amount: 100.10, date: september, userUuid: 'a'),
        _expense(amount: 200.20, date: september, userUuid: 'b', id: 2),
        _expense(amount: 55.55, date: september, userUuid: 'c', id: 3),
      ];
      const paid = {'a': 100.10, 'b': 200.20, 'c': 55.55};
      final total = paid.values.fold<double>(0, (sum, v) => sum + v);
      final share = total / 3;

      final transfers = settleDebts(
        expenses: expenses,
        members: const [_ana, _beto, _caro],
        year: 2026,
        month: 9,
      );

      expect(transfers, isNotEmpty);
      for (final member in const ['a', 'b', 'c']) {
        final expectedBalance = paid[member]! - share;
        expect(
          _netFor(transfers, member),
          closeTo(expectedBalance, 0.01),
          reason: 'member $member net flow must match paid - share',
        );
      }

      final balanceSum = paid.keys.fold<double>(0, (sum, uuid) {
        return sum + (paid[uuid]! - share);
      });
      expect(balanceSum, closeTo(0, 1e-9));
    });

    test('rounds to cents and conserves the total owed', () {
      // Total 1000 / 3 = 333.33... -> residual cent lands on last transfer.
      final expenses = [_expense(amount: 1000, date: september, userUuid: 'a')];

      final transfers = settleDebts(
        expenses: expenses,
        members: const [_ana, _beto, _caro],
        year: 2026,
        month: 9,
      );

      expect(transfers, hasLength(2));
      for (final transfer in transfers) {
        expect(transfer.toUuid, 'a');
        expect(transfer.amount, greaterThan(0));
        // Exactly two decimal places.
        final cents = transfer.amount * 100;
        expect(cents, closeTo(cents.roundToDouble(), 1e-6));
      }

      final amounts = transfers.map((t) => t.amount).toList()..sort();
      expect(amounts, [333.33, 333.34]);

      // Sum of transfers equals total owed (1000 - 1000/3) within 0.01.
      const totalOwed = 1000 - 1000 / 3;
      final sum = transfers.fold<double>(0, (s, t) => s + t.amount);
      expect(sum, closeTo(totalOwed, 0.01));
    });

    test('ignores expenses from other months', () {
      // Only the September expense counts: pot 100 -> share 50.
      final expenses = [
        _expense(amount: 100, date: september, userUuid: 'a'),
        _expense(
          amount: 500,
          date: DateTime(2026, 8, 15),
          userUuid: 'b',
          id: 2,
        ),
      ];

      final transfers = settleDebts(
        expenses: expenses,
        members: const [_ana, _beto],
        year: 2026,
        month: 9,
      );

      expect(transfers, [
        const DebtTransfer(
          fromUuid: 'b',
          fromName: 'Beto Gomez',
          toUuid: 'a',
          toName: 'Ana Perez',
          amount: 50,
        ),
      ]);
    });

    test('returns empty list when members list is empty', () {
      final expenses = [_expense(amount: 100, date: september, userUuid: 'a')];

      final transfers = settleDebts(
        expenses: expenses,
        members: const [],
        year: 2026,
        month: 9,
      );

      expect(transfers, isEmpty);
    });
  });
}
