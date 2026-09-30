import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/expenses/data/local/pending_expense_store.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:biyuya/src/features/expenses/provider/expense_repository_provider.dart';
import 'package:biyuya/src/features/expenses/provider/expense_sync_providers.dart';
import 'package:biyuya/src/features/expenses/provider/expenses_by_month_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../helpers/test_helpers.dart';

/// Session with no signed-in user — householdId resolves to null.
class FakeNullAuthSessionController extends AuthSessionController {
  @override
  FutureOr<UserProfile?> build() => null;
}

/// Repository holding expenses across two months; filters by the requested
/// (year, month) like the server does and records every call.
class FakeExpenseRepository extends Fake implements ExpenseRepositoryBase {
  FakeExpenseRepository(this.rows);

  final List<Expense> rows;
  final List<({int householdId, int year, int month})> calls = [];

  @override
  Future<Result<List<Expense>, ExpenseFailure>> getExpensesByMonth({
    required int householdId,
    required int year,
    required int month,
  }) async {
    calls.add((householdId: householdId, year: year, month: month));
    return Success([
      for (final expense in rows)
        if (expense.date.year == year && expense.date.month == month) expense,
    ]);
  }
}

/// In-memory outbox — no SharedPreferences.
class FakePendingExpenseStore extends PendingExpenseStore {
  FakePendingExpenseStore(this._items);

  final List<Expense> _items;

  @override
  Future<List<Expense>> load() async => List.of(_items);
}

Expense _expense({
  required int id,
  required double amount,
  required DateTime date,
  ExpenseSyncStatus syncStatus = ExpenseSyncStatus.synced,
}) {
  return Expense(
    id: id,
    amount: amount,
    date: date,
    householdId: 1,
    categoryId: 1,
    createdAt: date,
    syncStatus: syncStatus,
  );
}

void main() {
  final augSyncedOld = _expense(
    id: 1,
    amount: 100,
    date: DateTime(2026, 8, 10),
  );
  final augSyncedNew = _expense(
    id: 2,
    amount: 200,
    date: DateTime(2026, 8, 25),
  );
  final sepSynced = _expense(id: 3, amount: 300, date: DateTime(2026, 9, 5));
  final augPending = _expense(
    id: -1,
    amount: 150,
    date: DateTime(2026, 8, 15),
    syncStatus: ExpenseSyncStatus.pending,
  );
  final sepPending = _expense(
    id: -2,
    amount: 250,
    date: DateTime(2026, 9, 12),
    syncStatus: ExpenseSyncStatus.pending,
  );

  ProviderContainer makeContainer({
    required FakeExpenseRepository repo,
    required FakePendingExpenseStore store,
    bool signedIn = true,
  }) {
    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(repo),
        pendingExpenseStoreProvider.overrideWithValue(store),
        authSessionControllerProvider.overrideWith(
          signedIn
              ? FakeAuthSessionController.new
              : FakeNullAuthSessionController.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('expensesByMonthProvider', () {
    test(
      'returns only the requested month rows, its pending, date descending',
      () async {
        final repo = FakeExpenseRepository([
          augSyncedOld,
          augSyncedNew,
          sepSynced,
        ]);
        final store = FakePendingExpenseStore([augPending, sepPending]);
        final container = makeContainer(repo: repo, store: store);

        final rows = await container.read(
          expensesByMonthProvider(year: 2026, month: 8).future,
        );

        // 25/08 (synced) > 15/08 (pending) > 10/08 (synced): date desc.
        expect(rows.map((e) => e.id), [2, -1, 1]);
        expect(rows.map((e) => e.amount), [200.0, 150.0, 100.0]);
        expect(
          rows.every((e) => e.date.year == 2026 && e.date.month == 8),
          isTrue,
        );
        // No September row, synced or pending.
        expect(rows.map((e) => e.id), isNot(contains(3)));
        expect(rows.map((e) => e.id), isNot(contains(-2)));

        // Repository asked for the requested year/month, household 1.
        expect(repo.calls, [(householdId: 1, year: 2026, month: 8)]);

        // Requesting the other month returns that month only, still date
        // descending: pending 12/09 before synced 05/09.
        final sepRows = await container.read(
          expensesByMonthProvider(year: 2026, month: 9).future,
        );
        expect(sepRows.map((e) => e.id), [-2, 3]);
        expect(repo.calls.last, (householdId: 1, year: 2026, month: 9));
      },
    );

    test('returns empty list without session and skips repository', () async {
      final repo = FakeExpenseRepository([augSyncedOld, sepSynced]);
      final store = FakePendingExpenseStore([augPending]);
      final container = makeContainer(
        repo: repo,
        store: store,
        signedIn: false,
      );

      final rows = await container.read(
        expensesByMonthProvider(year: 2026, month: 8).future,
      );

      expect(rows, isEmpty);
      expect(repo.calls, isEmpty);
    });
  });
}
