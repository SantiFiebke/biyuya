import 'dart:async';

import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/provider/expense_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expense_controller.g.dart';

@Riverpod(keepAlive: true)
class ExpenseController extends _$ExpenseController {
  @override
  AsyncValue<List<Expense>> build() {
    unawaited(Future.microtask(_loadExpenses));
    return const AsyncData([]);
  }

  Future<void> _loadExpenses() async {
    final session = ref.read(authSessionControllerProvider);
    final householdId = session.value?.householdId;

    if (householdId == null || householdId.isEmpty) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();
    final repository = ref.read(expenseRepositoryProvider);
    final result = await repository.getExpenses(
      householdId: int.parse(householdId),
    );
    result.when(
      (expenses) => state = AsyncData(expenses),
      (failure) => state = AsyncError(failure, StackTrace.current),
    );
  }

  Future<void> loadExpensesByMonth({
    required int year,
    required int month,
  }) async {
    final session = ref.read(authSessionControllerProvider);
    final householdId = session.value?.householdId;

    if (householdId == null || householdId.isEmpty) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();
    final repository = ref.read(expenseRepositoryProvider);
    final result = await repository.getExpensesByMonth(
      householdId: int.parse(householdId),
      year: year,
      month: month,
    );
    result.when(
      (expenses) => state = AsyncData(expenses),
      (failure) => state = AsyncError(failure, StackTrace.current),
    );
  }

  String? get _userUuid {
    return ref.read(supabaseClientProvider).auth.currentUser?.id;
  }

  Future<bool> createExpense({
    required double amount,
    required DateTime date,
    required int categoryId,
    String? description,
  }) async {
    final session = ref.read(authSessionControllerProvider);
    final householdId = session.value?.householdId;
    final userUuid = _userUuid;

    if (householdId == null || householdId.isEmpty || userUuid == null) {
      return false;
    }

    final repository = ref.read(expenseRepositoryProvider);
    final result = await repository.createExpense(
      amount: amount,
      date: date,
      description: description,
      householdId: int.parse(householdId),
      categoryId: categoryId,
      userUuid: userUuid,
    );
    // The `when` callback runs synchronously on the result; no await needed.
    // ignore: async_return_with_no_await
    return result.when(
      (expense) {
        state = AsyncData([expense, ...state.value ?? []]);
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> updateExpense({
    required int id,
    required double amount,
    required DateTime date,
    required int categoryId,
    String? description,
  }) async {
    final repository = ref.read(expenseRepositoryProvider);
    final result = await repository.updateExpense(
      id: id,
      amount: amount,
      date: date,
      description: description,
      categoryId: categoryId,
    );
    // The `when` callback runs synchronously on the result; no await needed.
    // ignore: async_return_with_no_await
    return result.when(
      (updated) {
        final expenses = state.value ?? [];
        final index = expenses.indexWhere((e) => e.id == id);
        if (index != -1) {
          expenses[index] = updated;
          state = AsyncData(List.from(expenses));
        }
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> deleteExpense({required int id}) async {
    final repository = ref.read(expenseRepositoryProvider);
    final result = await repository.deleteExpense(id: id);
    // The `when` callback runs synchronously on the result; no await needed.
    // ignore: async_return_with_no_await
    return result.when(
      (_) {
        final expenses = state.value ?? [];
        state = AsyncData(expenses.where((e) => e.id != id).toList());
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }
}
