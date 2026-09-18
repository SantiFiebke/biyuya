import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/provider/expense_repository_provider.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockExpenseRepository mockRepo;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockExpenseRepository();
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();

    // Default: auto-load returns empty
    when(
      () => mockRepo.getExpenses(householdId: 1),
    ).thenAnswer((_) async => const Success([]));

    // Mock supabase client for _userUuid
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('test-user-id');

    SharedPreferences.setMockInitialValues({});

    container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(mockRepo),
        authSessionControllerProvider.overrideWith(
          FakeAuthSessionController.new,
        ),
        supabaseClientProvider.overrideWithValue(mockSupabaseClient),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ExpenseController', () {
    test('build returns empty list initially', () {
      final state = container.read(expenseControllerProvider);
      expect(state.value, isEmpty);
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
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => const Error(ExpenseFailure('db error')));

      container.read(expenseControllerProvider);
      await waitForLoad();

      expect(container.read(expenseControllerProvider).hasError, isTrue);
    });

    test('createExpense adds expense to state and returns true', () async {
      final newExpense = makeExpense(id: 3, amount: 250);
      when(
        () => mockRepo.createExpense(
          amount: 250,
          date: any(named: 'date'),
          householdId: 1,
          categoryId: 1,
          userUuid: 'test-user-id',
        ),
      ).thenAnswer((_) async => Success(newExpense));

      container.read(expenseControllerProvider);
      await waitForLoad();

      final notifier = container.read(expenseControllerProvider.notifier);
      final result = await notifier.createExpense(
        amount: 250,
        date: DateTime(2025),
        categoryId: 1,
      );

      expect(result, isTrue);
      final state = container.read(expenseControllerProvider);
      expect(state.value, hasLength(1));
      expect(state.value![0].amount, 250.0);
    });

    test('createExpense sets AsyncError on failure', () async {
      when(
        () => mockRepo.createExpense(
          amount: 999,
          date: any(named: 'date'),
          householdId: 1,
          categoryId: 1,
          userUuid: 'test-user-id',
        ),
      ).thenAnswer((_) async => const Error(ExpenseFailure('fail')));

      container.read(expenseControllerProvider);
      await waitForLoad();

      final notifier = container.read(expenseControllerProvider.notifier);
      final result = await notifier.createExpense(
        amount: 999,
        date: DateTime(2025),
        categoryId: 1,
      );

      expect(result, isFalse);
      expect(container.read(expenseControllerProvider).hasError, isTrue);
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
        date: DateTime(2025),
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
        date: DateTime(2025),
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

        final newExpense = todayExpense(id: 2, amount: 300);
        when(
          () => mockRepo.createExpense(
            amount: 300,
            date: any(named: 'date'),
            householdId: 1,
            categoryId: 1,
            userUuid: 'test-user-id',
          ),
        ).thenAnswer((_) async => Success(newExpense));

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

      final newExpense = todayExpense(id: 1, amount: 75);
      when(
        () => mockRepo.createExpense(
          amount: 75,
          date: any(named: 'date'),
          householdId: 1,
          categoryId: 1,
          userUuid: 'test-user-id',
        ),
      ).thenAnswer((_) async => Success(newExpense));

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
