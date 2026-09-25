import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/expenses/data/local/pending_expense_store.dart';
import 'package:biyuya/src/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_list_controller.dart';
import 'package:biyuya/src/features/expenses/provider/expense_repository_provider.dart';
import 'package:biyuya/src/features/expenses/provider/expense_sync_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../helpers/test_helpers.dart';

class MockExpenseRepository extends Mock implements ExpenseRepositoryImpl {}

/// In-memory [PendingExpenseStore] — never touches SharedPreferences.
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

/// Recorded arguments of one `getExpensesPage` call — stands in for asserting
/// the repository query (no Supabase query harness exists in this suite).
class PageCall {
  const PageCall({
    required this.householdId,
    required this.limit,
    required this.offset,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.userUuid,
  });

  final int householdId;
  final int limit;
  final int offset;
  final int? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? userUuid;
}

Expense expense({
  required int id,
  int categoryId = 1,
  DateTime? date,
  String? userUuid,
  String? clientId,
}) {
  return Expense(
    id: id,
    amount: 10,
    date: date ?? DateTime(2025, 7, (id % 28) + 1),
    householdId: 1,
    categoryId: categoryId,
    userUuid: userUuid,
    clientId: clientId,
    createdAt: DateTime(2025, 7),
  );
}

void main() {
  late MockExpenseRepository repo;
  late FakePendingExpenseStore store;
  late List<PageCall> calls;
  late List<Expense> serverItems;
  late ExpenseFailure? failure;
  late ProviderContainer container;

  /// Drain the event loop so the build microtask + refresh complete.
  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    repo = MockExpenseRepository();
    store = FakePendingExpenseStore();
    calls = [];
    serverItems = [];
    failure = null;

    // Fake server: records every call, applies filters + range like the real
    // Supabase query (eq/gte/lte + order desc + range(offset, offset+limit)).
    when(
      () => repo.getExpensesPage(
        householdId: any(named: 'householdId'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
        categoryId: any(named: 'categoryId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        userUuid: any(named: 'userUuid'),
      ),
    ).thenAnswer((invocation) async {
      final args = invocation.namedArguments;
      final call = PageCall(
        householdId: args[#householdId] as int,
        limit: args[#limit] as int,
        offset: args[#offset] as int,
        categoryId: args[#categoryId] as int?,
        startDate: args[#startDate] as DateTime?,
        endDate: args[#endDate] as DateTime?,
        userUuid: args[#userUuid] as String?,
      );
      calls.add(call);

      final error = failure;
      if (error != null) {
        return Error(error);
      }

      final filtered = serverItems.where((e) {
        if (call.categoryId != null && e.categoryId != call.categoryId) {
          return false;
        }
        if (call.userUuid != null && e.userUuid != call.userUuid) {
          return false;
        }
        if (call.startDate != null && e.date.isBefore(call.startDate!)) {
          return false;
        }
        if (call.endDate != null && e.date.isAfter(call.endDate!)) {
          return false;
        }
        return true;
      }).toList();
      return Success(filtered.skip(call.offset).take(call.limit).toList());
    });

    container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(repo),
        authSessionControllerProvider.overrideWith(
          FakeAuthSessionController.new,
        ),
        pendingExpenseStoreProvider.overrideWithValue(store),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('ExpenseListController pagination', () {
    test(
      'first full page loads pageSize items, hasMore=true, query args',
      () async {
        serverItems = List.generate(40, (i) => expense(id: i + 1));

        container.read(expenseListControllerProvider);
        await settle();

        final state = container.read(expenseListControllerProvider);
        expect(state.items, hasLength(ExpenseListController.pageSize));
        expect(state.hasMore, isTrue);
        expect(state.isLoadingMore, isFalse);
        expect(state.error, isNull);

        // B1: the query the controller builds for page 0.
        expect(calls, hasLength(1));
        final call = calls.single;
        expect(call.householdId, 1);
        expect(call.limit, ExpenseListController.pageSize);
        expect(call.offset, 0);
        expect(call.categoryId, isNull);
        expect(call.startDate, isNull);
        expect(call.endDate, isNull);
        expect(call.userUuid, isNull);
      },
    );

    test('short first page sets hasMore=false', () async {
      serverItems = List.generate(5, (i) => expense(id: i + 1));

      container.read(expenseListControllerProvider);
      await settle();

      final state = container.read(expenseListControllerProvider);
      expect(state.items, hasLength(5));
      expect(state.hasMore, isFalse);
    });

    test('loadMore appends the next page and stops on a short page', () async {
      serverItems = List.generate(35, (i) => expense(id: i + 1));

      container.read(expenseListControllerProvider);
      await settle();

      final notifier = container.read(expenseListControllerProvider.notifier);
      await notifier.loadMore();
      await settle();

      final state = container.read(expenseListControllerProvider);
      expect(state.items, hasLength(35));
      expect(state.hasMore, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.items.first.id, 1);
      expect(state.items.last.id, 35);

      expect(calls, hasLength(2));
      expect(calls[1].offset, ExpenseListController.pageSize);
      expect(calls[1].limit, ExpenseListController.pageSize);
    });

    test('loadMore is a no-op when hasMore=false', () async {
      serverItems = List.generate(3, (i) => expense(id: i + 1));

      container.read(expenseListControllerProvider);
      await settle();

      await container.read(expenseListControllerProvider.notifier).loadMore();
      await settle();

      expect(calls, hasLength(1));
    });

    test('refresh resets offset to 0 after loadMore', () async {
      serverItems = List.generate(40, (i) => expense(id: i + 1));

      container.read(expenseListControllerProvider);
      await settle();

      final notifier = container.read(expenseListControllerProvider.notifier);
      await notifier.loadMore();
      await settle();
      expect(calls[1].offset, 30);

      await notifier.refresh();
      await settle();

      expect(calls.last.offset, 0);
      final state = container.read(expenseListControllerProvider);
      expect(state.items, hasLength(ExpenseListController.pageSize));
      expect(state.hasMore, isTrue);
    });

    test('load failure surfaces error and keeps list empty', () async {
      failure = const ExpenseFailure('boom');

      container.read(expenseListControllerProvider);
      await settle();

      final state = container.read(expenseListControllerProvider);
      expect(state.error, isA<ExpenseFailure>());
      expect(state.items, isEmpty);
    });
  });

  group('ExpenseListController filters', () {
    test(
      'setFilters(categoryId) reloads from offset 0 with the filter',
      () async {
        serverItems = [
          for (var i = 1; i <= 40; i++)
            expense(id: i, categoryId: i.isEven ? 2 : 1),
        ];

        container.read(expenseListControllerProvider);
        await settle();
        expect(
          container.read(expenseListControllerProvider).items,
          hasLength(30),
        );

        await container
            .read(expenseListControllerProvider.notifier)
            .setFilters(categoryId: 2);
        await settle();

        final state = container.read(expenseListControllerProvider);
        expect(state.items, hasLength(20));
        expect(state.items.every((e) => e.categoryId == 2), isTrue);
        expect(calls.last.offset, 0);
        expect(calls.last.categoryId, 2);
      },
    );

    test(
      'setFilters passes date range and userUuid through to the query',
      () async {
        serverItems = [expense(id: 1)];

        container.read(expenseListControllerProvider);
        await settle();

        final start = DateTime(2025, 7);
        final end = DateTime(2025, 7, 31, 23, 59, 59);
        await container
            .read(expenseListControllerProvider.notifier)
            .setFilters(startDate: start, endDate: end, userUuid: 'user-9');
        await settle();

        final call = calls.last;
        expect(call.startDate, start);
        expect(call.endDate, end);
        expect(call.userUuid, 'user-9');
        expect(call.offset, 0);
      },
    );

    test(
      'clearFilters removes category, dates and user from the query',
      () async {
        serverItems = [expense(id: 1)];

        container.read(expenseListControllerProvider);
        await settle();

        final notifier = container.read(expenseListControllerProvider.notifier);
        await notifier.setFilters(categoryId: 2, userUuid: 'u');
        await notifier.clearFilters();
        await settle();

        final call = calls.last;
        expect(call.categoryId, isNull);
        expect(call.startDate, isNull);
        expect(call.endDate, isNull);
        expect(call.userUuid, isNull);
        expect(call.offset, 0);
      },
    );
  });

  group('ExpenseListController pending outbox', () {
    test('pending expenses are prepended and deduped by clientId', () async {
      final pending = Expense(
        id: -1,
        amount: 50,
        date: DateTime(2025, 7, 20),
        householdId: 1,
        categoryId: 1,
        createdAt: DateTime(2025, 7, 20),
        clientId: 'c1',
        syncStatus: ExpenseSyncStatus.pending,
      );
      await store.add(pending);
      // Server already holds the synced row for the same clientId.
      serverItems = [
        expense(id: 100, clientId: 'c1'),
        for (var i = 2; i <= 31; i++) expense(id: i),
      ];

      container.read(expenseListControllerProvider);
      await settle();

      final state = container.read(expenseListControllerProvider);
      // 30 page rows - 1 duplicate + 1 pending prepended.
      expect(state.items, hasLength(30));
      expect(state.items.first.clientId, 'c1');
      expect(state.items.first.id, -1);
      expect(state.items.where((e) => e.clientId == 'c1'), hasLength(1));
      expect(state.hasMore, isTrue);
    });
  });
}
