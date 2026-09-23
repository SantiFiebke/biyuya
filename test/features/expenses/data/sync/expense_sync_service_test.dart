import 'dart:async';

import 'package:biyuya/src/features/expenses/data/local/pending_expense_store.dart';
import 'package:biyuya/src/features/expenses/data/sync/expense_sync_service.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

/// In-memory [PendingExpenseStore] — no SharedPreferences.
class FakePendingExpenseStore extends PendingExpenseStore {
  FakePendingExpenseStore([List<Expense> initial = const []])
    : _items = [...initial];

  final List<Expense> _items;

  List<Expense> get items => List.unmodifiable(_items);

  @override
  Future<List<Expense>> load() async => List.of(_items);

  @override
  Future<void> save(List<Expense> pending) async {
    _items
      ..clear()
      ..addAll(pending);
  }

  @override
  Future<void> add(Expense expense) async => _items.add(expense);

  @override
  Future<void> remove(String clientId) async =>
      _items.removeWhere((e) => e.clientId == clientId);

  @override
  Future<void> clear() async => _items.clear();
}

/// Fake repo with a pluggable [onCreate] handler and call log.
class FakeExpenseRepository extends ExpenseRepositoryBase {
  final List<String?> createdClientIds = [];

  Result<Expense, ExpenseFailure> defaultResult = const Error(
    ExpenseFailure('unexpected call'),
  );

  Future<Result<Expense, ExpenseFailure>> Function(String clientId)? onCreate;

  @override
  Future<Result<Expense, ExpenseFailure>> createExpense({
    required double amount,
    required DateTime date,
    required int householdId,
    required int categoryId,
    required String userUuid,
    String? description,
    String? clientId,
  }) {
    createdClientIds.add(clientId);
    final handler = onCreate;
    if (handler != null) {
      return handler(clientId!);
    }
    return Future.value(defaultResult);
  }

  @override
  Future<Result<List<Expense>, ExpenseFailure>> getExpenses({
    required int householdId,
  }) async => const Success([]);

  @override
  Future<Result<List<Expense>, ExpenseFailure>> getExpensesByMonth({
    required int householdId,
    required int year,
    required int month,
  }) async => const Success([]);

  @override
  Future<Result<Expense, ExpenseFailure>> updateExpense({
    required int id,
    required double amount,
    required DateTime date,
    required int categoryId,
    String? description,
  }) async => const Error(ExpenseFailure('not implemented'));

  @override
  Future<Result<void, ExpenseFailure>> deleteExpense({required int id}) async =>
      const Success(null);
}

Expense makePending({
  String? clientId = 'client-1',
  String? userUuid = 'user-1',
  double amount = 100,
}) {
  return Expense(
    id: -1,
    amount: amount,
    date: DateTime(2025, 1, 15),
    householdId: 1,
    categoryId: 1,
    createdAt: DateTime(2025, 1, 15),
    clientId: clientId,
    userUuid: userUuid,
    syncStatus: ExpenseSyncStatus.pending,
  );
}

void main() {
  late FakePendingExpenseStore store;
  late FakeExpenseRepository repo;
  late ExpenseSyncService service;

  setUp(() {
    store = FakePendingExpenseStore();
    repo = FakeExpenseRepository()
      ..defaultResult = Success(makePending(clientId: 'ok'));
    service = ExpenseSyncService(repo, store);
  });

  group('ExpenseSyncService.flush', () {
    test('success: syncs all pending and empties store', () async {
      store = FakePendingExpenseStore([
        makePending(clientId: 'c1', userUuid: 'u1'),
        makePending(clientId: 'c2', userUuid: 'u1'),
      ]);
      service = ExpenseSyncService(repo, store);

      final summary = await service.flush();

      expect(summary.synced, 2);
      expect(summary.failed, 0);
      expect(summary.errors, isEmpty);
      expect(store.items, isEmpty);
      expect(repo.createdClientIds, containsAll(['c1', 'c2']));
    });

    test('failure: item remains in store, error recorded', () async {
      store = FakePendingExpenseStore([makePending(clientId: 'c1')]);
      service = ExpenseSyncService(repo, store);
      repo.defaultResult = const Error(ExpenseFailure('network down'));

      final summary = await service.flush();

      expect(summary.synced, 0);
      expect(summary.failed, 1);
      expect(summary.errors, ['network down']);
      expect(store.items, hasLength(1));
      expect(store.items.single.clientId, 'c1');
    });

    test(
      'missing clientId/userUuid: skipped, remains, error recorded',
      () async {
        store = FakePendingExpenseStore([
          makePending(clientId: null),
          makePending(userUuid: null),
        ]);
        service = ExpenseSyncService(repo, store);

        final summary = await service.flush();

        expect(summary.synced, 0);
        expect(summary.failed, 2);
        expect(summary.errors, everyElement(contains('sin clientId/userUuid')));
        expect(store.items, hasLength(2));
        expect(repo.createdClientIds, isEmpty);
      },
    );

    test(
      're-entrancy: concurrent flush returns empty, no double-process',
      () async {
        store = FakePendingExpenseStore([makePending(clientId: 'c1')]);
        service = ExpenseSyncService(repo, store);

        final completer = Completer<Result<Expense, ExpenseFailure>>();
        repo.onCreate = (_) => completer.future;

        final first = service.flush();
        // Give first flush a chance to reach createExpense and set _isSyncing.
        await Future<void>.delayed(Duration.zero);

        expect(service.isSyncing, isTrue);
        final second = await service.flush();
        expect(second.synced, 0);
        expect(second.failed, 0);
        expect(second.errors, isEmpty);

        completer.complete(Success(makePending(clientId: 'c1')));
        final firstSummary = await first;

        expect(firstSummary.synced, 1);
        expect(repo.createdClientIds, ['c1']);
        expect(store.items, isEmpty);
        expect(service.isSyncing, isFalse);
      },
    );
  });
}
