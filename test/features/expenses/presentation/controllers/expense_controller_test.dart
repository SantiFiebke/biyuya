import 'dart:async';

import 'package:biyuya/src/core/network/connectivity_provider.dart';
import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/expenses/data/local/pending_expense_store.dart';
import 'package:biyuya/src/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/provider/expense_repository_provider.dart';
import 'package:biyuya/src/features/expenses/provider/expense_sync_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../helpers/test_helpers.dart';

class MockExpenseRepository extends Mock implements ExpenseRepositoryImpl {}

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

class MockUser extends Mock implements supabase.User {}

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

Expense pendingExpense({
  int id = -1,
  String clientId = 'client-1',
  String userUuid = 'test-user-id',
  double amount = 100,
  DateTime? date,
}) {
  return Expense(
    id: id,
    amount: amount,
    date: date ?? DateTime(2025, 7),
    householdId: 1,
    categoryId: 1,
    createdAt: DateTime(2025, 7),
    clientId: clientId,
    userUuid: userUuid,
    syncStatus: ExpenseSyncStatus.pending,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockExpenseRepository mockRepo;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;
  late FakePendingExpenseStore store;
  late ProviderContainer container;

  /// Stub for the sync service's flush call (all named args).
  void stubCreateExpense(
    Future<Result<Expense, ExpenseFailure>> Function() answer,
  ) {
    when(
      () => mockRepo.createExpense(
        amount: any(named: 'amount'),
        date: any(named: 'date'),
        householdId: any(named: 'householdId'),
        categoryId: any(named: 'categoryId'),
        userUuid: any(named: 'userUuid'),
        description: any(named: 'description'),
        clientId: any(named: 'clientId'),
      ),
    ).thenAnswer((_) => answer());
  }

  ProviderContainer createContainer({Stream<bool>? online}) {
    return ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(mockRepo),
        authSessionControllerProvider.overrideWith(
          FakeAuthSessionController.new,
        ),
        supabaseClientProvider.overrideWithValue(mockSupabaseClient),
        pendingExpenseStoreProvider.overrideWithValue(store),
        isOnlineProvider.overrideWith(
          (ref) => online ?? Stream<bool>.value(true),
        ),
      ],
    );
  }

  /// Rebuild the container with a custom connectivity stream.
  void recreateContainer({Stream<bool>? online}) {
    container.dispose();
    container = createContainer(online: online);
  }

  /// Drain the event loop so unawaited flush/reload work completes.
  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    mockRepo = MockExpenseRepository();
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();
    store = FakePendingExpenseStore();

    // Default: auto-load returns empty.
    when(
      () => mockRepo.getExpenses(householdId: 1),
    ).thenAnswer((_) async => const Success([]));

    // Default: sync flush succeeds with a server expense.
    stubCreateExpense(() async => Success(makeExpense(id: 99)));

    // Mock supabase client for _userUuid.
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('test-user-id');

    SharedPreferences.setMockInitialValues({});

    container = createContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('ExpenseController', () {
    test('build returns empty list initially', () async {
      final state = container.read(expenseControllerProvider);
      expect(state.value, isEmpty);
      // Drain the unawaited _loadExpenses microtask before teardown.
      await settle();
    });

    test('build auto-loads expenses from repository', () async {
      final expenses = [
        makeExpense(description: 'Food'),
        makeExpense(id: 2, description: 'Transport'),
      ];
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => Success(expenses));

      container.read(expenseControllerProvider);
      await waitForLoad();

      final state = container.read(expenseControllerProvider);
      expect(state.value, hasLength(2));
      expect(state.value![0].description, 'Food');
    });

    test('build sets AsyncError on load failure', () async {
      // No connectivity event: avoid the reconnect retrySync overwriting state.
      recreateContainer(online: Stream<bool>.value(false));
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => const Error(ExpenseFailure('db error')));

      container.read(expenseControllerProvider);
      await waitForLoad();

      expect(container.read(expenseControllerProvider).hasError, isTrue);
    });

    test(
      'createExpense adds pending expense to state and returns true',
      () async {
        container.read(expenseControllerProvider);
        await waitForLoad();

        final notifier = container.read(expenseControllerProvider.notifier);
        final result = await notifier.createExpense(
          amount: 250,
          date: DateTime(2025, 7),
          categoryId: 1,
        );

        expect(result, isTrue);
        final state = container.read(expenseControllerProvider);
        expect(state.value, hasLength(1));
        expect(state.value!.single.amount, 250.0);
        expect(state.value!.single.syncStatus, ExpenseSyncStatus.pending);
        expect(state.value!.single.id, lessThan(0));

        await settle();
      },
    );

    test('createExpense returns false when userUuid missing', () async {
      when(() => mockGoTrueClient.currentUser).thenReturn(null);

      container.read(expenseControllerProvider);
      await waitForLoad();

      final notifier = container.read(expenseControllerProvider.notifier);
      final result = await notifier.createExpense(
        amount: 999,
        date: DateTime(2025, 7),
        categoryId: 1,
      );

      expect(result, isFalse);
    });

    test('submitExpense re-entry is rejected while in flight', () async {
      container.read(expenseControllerProvider);
      await waitForLoad();

      final notifier = container.read(expenseControllerProvider.notifier);
      final first = notifier.submitExpense(
        amount: 100,
        date: DateTime(2025, 7),
        categoryId: 1,
      );
      final second = notifier.submitExpense(
        amount: 100,
        date: DateTime(2025, 7),
        categoryId: 1,
      );

      expect(await first, isTrue);
      expect(await second, isFalse);
      // Only one pending expense reached the outbox.
      expect(store.items, hasLength(1));
      await settle();
    });

    test('updateExpense updates existing expense in state', () async {
      final initial = makeExpense(id: 5);
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => Success([initial]));

      container.read(expenseControllerProvider);
      await waitForLoad();

      final updated = makeExpense(id: 5, amount: 200);
      when(
        () => mockRepo.updateExpense(
          id: 5,
          amount: 200,
          date: any(named: 'date'),
          categoryId: 1,
        ),
      ).thenAnswer((_) async => Success(updated));

      final notifier = container.read(expenseControllerProvider.notifier);
      final result = await notifier.updateExpense(
        id: 5,
        amount: 200,
        date: DateTime(2025, 7),
        categoryId: 1,
      );

      expect(result, isTrue);
      final state = container.read(expenseControllerProvider);
      expect(state.value!.first.amount, 200.0);
    });

    test('updateExpense sets AsyncError on failure', () async {
      when(
        () => mockRepo.updateExpense(
          id: 5,
          amount: 200,
          date: any(named: 'date'),
          categoryId: 1,
        ),
      ).thenAnswer((_) async => const Error(ExpenseFailure('err')));

      container.read(expenseControllerProvider);
      await waitForLoad();

      final notifier = container.read(expenseControllerProvider.notifier);
      final result = await notifier.updateExpense(
        id: 5,
        amount: 200,
        date: DateTime(2025, 7),
        categoryId: 1,
      );

      expect(result, isFalse);
      expect(container.read(expenseControllerProvider).hasError, isTrue);
    });

    test('deleteExpense removes expense from state', () async {
      when(() => mockRepo.getExpenses(householdId: 1)).thenAnswer(
        (_) async => Success([
          makeExpense(description: 'A'),
          makeExpense(id: 2, description: 'B'),
        ]),
      );

      container.read(expenseControllerProvider);
      await waitForLoad();

      when(
        () => mockRepo.deleteExpense(id: 1),
      ).thenAnswer((_) async => const Success(null));

      final notifier = container.read(expenseControllerProvider.notifier);
      final result = await notifier.deleteExpense(id: 1);

      expect(result, isTrue);
      final state = container.read(expenseControllerProvider);
      expect(state.value, hasLength(1));
      expect(state.value![0].id, 2);
    });

    test('deleteExpense sets AsyncError on failure', () async {
      when(
        () => mockRepo.deleteExpense(id: 99),
      ).thenAnswer((_) async => const Error(ExpenseFailure('not found')));

      container.read(expenseControllerProvider);
      await waitForLoad();

      final notifier = container.read(expenseControllerProvider.notifier);
      final result = await notifier.deleteExpense(id: 99);

      expect(result, isFalse);
      expect(container.read(expenseControllerProvider).hasError, isTrue);
    });
  });

  group('ExpenseController offline flow', () {
    test(
      'createExpense offline returns true, keeps pending, no sync repo await',
      () async {
        final completer = Completer<Result<Expense, ExpenseFailure>>();
        stubCreateExpense(() => completer.future);

        container.read(expenseControllerProvider);
        await waitForLoad();

        final notifier = container.read(expenseControllerProvider.notifier);
        final result = await notifier.createExpense(
          amount: 50,
          date: DateTime(2025, 7),
          categoryId: 1,
        );

        // Returns before the (blocked) flush resolves.
        expect(result, isTrue);
        final state = container.read(expenseControllerProvider);
        expect(state.value, hasLength(1));
        expect(state.value!.single.syncStatus, ExpenseSyncStatus.pending);
        expect(state.value!.single.id, lessThan(0));

        completer.complete(const Error(ExpenseFailure('offline')));
        await settle();

        // Failed flush leaves the pending expense in place.
        expect(
          container.read(expenseControllerProvider).value!.single.syncStatus,
          ExpenseSyncStatus.pending,
        );
        expect(store.items, hasLength(1));
      },
    );

    test(
      'network failure with pending -> AsyncData(pending), not error',
      () async {
        recreateContainer(online: Stream<bool>.value(false));
        await store.add(pendingExpense(clientId: 'c1'));
        when(
          () => mockRepo.getExpenses(householdId: 1),
        ).thenAnswer((_) async => const Error(ExpenseFailure('down')));

        container.read(expenseControllerProvider);
        await waitForLoad();

        final state = container.read(expenseControllerProvider);
        expect(state.hasError, isFalse);
        expect(state.value, hasLength(1));
        expect(state.value!.single.clientId, 'c1');
      },
    );

    test('retrySync network failure with no pending -> AsyncError, not '
        'AsyncData([])', () async {
      // Regression (TASK-016): the reload path must surface the failure when
      // the outbox is empty instead of wiping state to AsyncData([]).
      recreateContainer(online: Stream<bool>.value(false));
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => const Error(ExpenseFailure('down')));

      container.read(expenseControllerProvider);
      await waitForLoad();
      expect(container.read(expenseControllerProvider).hasError, isTrue);

      final notifier = container.read(expenseControllerProvider.notifier);
      await notifier.retrySync();

      final state = container.read(expenseControllerProvider);
      expect(state, isA<AsyncError<List<Expense>>>());
      expect(state.hasError, isTrue);
      expect(state.hasValue, isFalse);
    });

    test(
      'reconnect flushes pending and replaces with server expense',
      () async {
        final online = StreamController<bool>.broadcast();
        recreateContainer(online: online.stream);
        // Keep the autoDispose connectivity provider alive for the test.
        final onlineSub = container.listen(isOnlineProvider, (_, _) {});
        await store.add(pendingExpense(clientId: 'c1'));

        when(
          () => mockRepo.getExpenses(householdId: 1),
        ).thenAnswer((_) async => const Error(ExpenseFailure('down')));
        final server = makeExpense(id: 42);
        stubCreateExpense(() async => Success(server));

        container.read(expenseControllerProvider);
        await waitForLoad();
        expect(
          container.read(expenseControllerProvider).value!.single.syncStatus,
          ExpenseSyncStatus.pending,
        );

        // First emission is the provider's initial value; emit offline then
        // online so the reconnect transition actually fires the listener.
        online.add(false);
        await settle();

        // Network back: server now returns the synced expense.
        when(
          () => mockRepo.getExpenses(householdId: 1),
        ).thenAnswer((_) async => Success([server]));
        online.add(true);
        await settle();

        final state = container.read(expenseControllerProvider);
        expect(state.value, hasLength(1));
        expect(state.value!.single.id, 42);
        expect(state.value!.single.syncStatus, ExpenseSyncStatus.synced);
        expect(store.items, isEmpty);

        onlineSub.close();
        // Not awaited: the controller's ref.listen subscription stays active
        // until the container is disposed in tearDown.
        unawaited(online.close());
      },
    );

    test('discardPending removes it from state and store', () async {
      recreateContainer(online: Stream<bool>.value(false));
      await store.add(pendingExpense(clientId: 'c1'));
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => const Success([]));

      container.read(expenseControllerProvider);
      await waitForLoad();
      expect(container.read(expenseControllerProvider).value, hasLength(1));

      final notifier = container.read(expenseControllerProvider.notifier);
      final result = await notifier.discardPending('c1');

      expect(result, isTrue);
      expect(container.read(expenseControllerProvider).value, isEmpty);
      expect(store.items, isEmpty);
    });

    test(
      'updateExpense on pending expense returns false, no network',
      () async {
        recreateContainer(online: Stream<bool>.value(false));
        await store.add(pendingExpense(id: -7, clientId: 'c1'));
        when(
          () => mockRepo.getExpenses(householdId: 1),
        ).thenAnswer((_) async => const Success([]));

        container.read(expenseControllerProvider);
        await waitForLoad();

        final notifier = container.read(expenseControllerProvider.notifier);
        final result = await notifier.updateExpense(
          id: -7,
          amount: 999,
          date: DateTime(2025, 7),
          categoryId: 1,
        );

        expect(result, isFalse);
        verifyNever(
          () => mockRepo.updateExpense(
            id: any(named: 'id'),
            amount: any(named: 'amount'),
            date: any(named: 'date'),
            categoryId: any(named: 'categoryId'),
            description: any(named: 'description'),
          ),
        );
      },
    );

    test('deleteExpense on pending discards without network', () async {
      recreateContainer(online: Stream<bool>.value(false));
      await store.add(pendingExpense(id: -5, clientId: 'c1'));
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => const Success([]));

      container.read(expenseControllerProvider);
      await waitForLoad();

      final notifier = container.read(expenseControllerProvider.notifier);
      final result = await notifier.deleteExpense(id: -5);

      expect(result, isTrue);
      expect(container.read(expenseControllerProvider).value, isEmpty);
      expect(store.items, isEmpty);
      verifyNever(() => mockRepo.deleteExpense(id: any(named: 'id')));
    });
  });

  group('Widget daily total sync', () {
    late List<MethodCall> refreshCalls;

    setUp(() {
      refreshCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('biyuya/widget'), (
            methodCall,
          ) async {
            refreshCalls.add(methodCall);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('biyuya/widget'), null);
    });

    Expense todayExpense({required int id, required double amount}) {
      final now = DateTime.now();
      return Expense(
        id: id,
        amount: amount,
        date: DateTime(now.year, now.month, now.day),
        householdId: 1,
        categoryId: 1,
        createdAt: DateTime.now(),
      );
    }

    Expense pastExpense({required int id, required double amount}) {
      return Expense(
        id: id,
        amount: amount,
        date: DateTime(2025, 1, 15),
        householdId: 1,
        categoryId: 1,
        createdAt: DateTime(2025, 1, 15),
      );
    }

    /// Pump event loop enough for unawaited syncTotal to complete.
    Future<void> pumpForSync() async {
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }

    test("loads expenses → SharedPreferences has only today's total", () async {
      final today1 = todayExpense(id: 1, amount: 150);
      final today2 = todayExpense(id: 2, amount: 250);
      final past = pastExpense(id: 3, amount: 500);
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => Success([today1, today2, past]));

      container.read(expenseControllerProvider);
      await waitForLoad();
      await pumpForSync();

      final prefs = await SharedPreferences.getInstance();
      // Only today: 150 + 250 = 400
      expect(prefs.getString('widget_daily_total'), '400.0');

      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(prefs.getString('widget_daily_date'), today);
    });

    test('past expenses only → total is 0.0', () async {
      final past = pastExpense(id: 1, amount: 999);
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => Success([past]));

      container.read(expenseControllerProvider);
      await waitForLoad();
      await pumpForSync();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('widget_daily_total'), '0.0');
    });

    test(
      'createExpense recalculates total and writes SharedPreferences',
      () async {
        final existing = todayExpense(id: 1, amount: 100);
        when(
          () => mockRepo.getExpenses(householdId: 1),
        ).thenAnswer((_) async => Success([existing]));

        container.read(expenseControllerProvider);
        await waitForLoad();
        await pumpForSync();

        // Offline: flush fails so the pending expense stays in state.
        stubCreateExpense(() async => const Error(ExpenseFailure('offline')));

        final notifier = container.read(expenseControllerProvider.notifier);
        final now = DateTime.now();
        final result = await notifier.createExpense(
          amount: 300,
          date: DateTime(now.year, now.month, now.day),
          categoryId: 1,
        );

        expect(result, isTrue);
        await pumpForSync();

        final prefs = await SharedPreferences.getInstance();
        // 100 + 300 = 400
        expect(prefs.getString('widget_daily_total'), '400.0');
      },
    );

    test('deleteExpense recalculates total', () async {
      final exp1 = todayExpense(id: 1, amount: 200);
      final exp2 = todayExpense(id: 2, amount: 300);
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => Success([exp1, exp2]));

      container.read(expenseControllerProvider);
      await waitForLoad();
      await pumpForSync();

      when(
        () => mockRepo.deleteExpense(id: 1),
      ).thenAnswer((_) async => const Success(null));

      final notifier = container.read(expenseControllerProvider.notifier);
      final result = await notifier.deleteExpense(id: 1);

      expect(result, isTrue);
      await pumpForSync();

      final prefs = await SharedPreferences.getInstance();
      // After deleting exp1 (200), only exp2 (300) remains
      expect(prefs.getString('widget_daily_total'), '300.0');
    });

    test('updateExpense recalculates total', () async {
      final exp1 = todayExpense(id: 1, amount: 100);
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => Success([exp1]));

      container.read(expenseControllerProvider);
      await waitForLoad();
      await pumpForSync();

      final updated = todayExpense(id: 1, amount: 500);
      when(
        () => mockRepo.updateExpense(
          id: 1,
          amount: 500,
          date: any(named: 'date'),
          categoryId: 1,
        ),
      ).thenAnswer((_) async => Success(updated));

      final notifier = container.read(expenseControllerProvider.notifier);
      final now = DateTime.now();
      final result = await notifier.updateExpense(
        id: 1,
        amount: 500,
        date: DateTime(now.year, now.month, now.day),
        categoryId: 1,
      );

      expect(result, isTrue);
      await pumpForSync();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('widget_daily_total'), '500.0');
    });

    test('refresh MethodChannel is called after loading expenses', () async {
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => Success([todayExpense(id: 1, amount: 50)]));

      container.read(expenseControllerProvider);
      await waitForLoad();
      await pumpForSync();

      expect(refreshCalls, isNotEmpty);
      expect(refreshCalls.last.method, 'refresh');
    });

    test('refresh MethodChannel is called after createExpense', () async {
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => const Success([]));

      container.read(expenseControllerProvider);
      await waitForLoad();
      await pumpForSync();

      refreshCalls.clear();

      // Offline: flush fails, pending stays, refresh still fires.
      stubCreateExpense(() async => const Error(ExpenseFailure('offline')));

      final notifier = container.read(expenseControllerProvider.notifier);
      final now = DateTime.now();
      await notifier.createExpense(
        amount: 75,
        date: DateTime(now.year, now.month, now.day),
        categoryId: 1,
      );
      await pumpForSync();

      expect(refreshCalls, isNotEmpty);
      expect(refreshCalls.last.method, 'refresh');
    });
  });
}
