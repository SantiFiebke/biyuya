import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/provider/expense_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockExpenseRepository extends Mock implements ExpenseRepositoryImpl {}

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

class MockUser extends Mock implements supabase.User {}

class _FakeAuthSessionController extends AuthSessionController {
  @override
  FutureOr<UserProfile?> build() => const UserProfile(
    id: 'test-user-id',
    name: 'Test',
    lastName: 'User',
    householdId: '1',
  );
}

Expense _makeExpense({
  int id = 1,
  double amount = 100.0,
  String? description = 'Test expense',
  int householdId = 1,
  int categoryId = 1,
}) {
  return Expense(
    id: id,
    amount: amount,
    date: DateTime(2025),
    description: description,
    householdId: householdId,
    categoryId: categoryId,
    userUuid: 'test-user-id',
    createdAt: DateTime(2025),
  );
}

/// Wait for build()'s Future.microtask auto-load to settle.
Future<void> _waitForLoad() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
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

    container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(mockRepo),
        authSessionControllerProvider.overrideWith(
          _FakeAuthSessionController.new,
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
        _makeExpense(description: 'Food'),
        _makeExpense(id: 2, description: 'Transport'),
      ];
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => Success(expenses));

      container.read(expenseControllerProvider);
      await _waitForLoad();

      final state = container.read(expenseControllerProvider);
      expect(state.value, hasLength(2));
      expect(state.value![0].description, 'Food');
    });

    test('build sets AsyncError on load failure', () async {
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => const Error(ExpenseFailure('db error')));

      container.read(expenseControllerProvider);
      await _waitForLoad();

      expect(container.read(expenseControllerProvider).hasError, isTrue);
    });

    test('createExpense adds expense to state and returns true', () async {
      final newExpense = _makeExpense(id: 3, amount: 250);
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
      await _waitForLoad();

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
      await _waitForLoad();

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
      final initial = _makeExpense(id: 5);
      when(
        () => mockRepo.getExpenses(householdId: 1),
      ).thenAnswer((_) async => Success([initial]));

      container.read(expenseControllerProvider);
      await _waitForLoad();

      final updated = _makeExpense(id: 5, amount: 200);
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
      await _waitForLoad();

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
          _makeExpense(description: 'A'),
          _makeExpense(id: 2, description: 'B'),
        ]),
      );

      container.read(expenseControllerProvider);
      await _waitForLoad();

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
      await _waitForLoad();

      final notifier = container.read(expenseControllerProvider.notifier);
      final result = await notifier.deleteExpense(id: 99);

      expect(result, isFalse);
      expect(container.read(expenseControllerProvider).hasError, isTrue);
    });
  });
}
