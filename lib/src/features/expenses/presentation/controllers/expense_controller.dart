import 'dart:async';

import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/provider/expense_repository_provider.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/report_controller.dart';
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

    final previous = state.value ?? [];
    state = const AsyncLoading();
    final repository = ref.read(expenseRepositoryProvider);
    final result = await repository.createExpense(
      amount: amount,
      date: date,
      description: description,
      householdId: int.parse(householdId),
      categoryId: categoryId,
      userUuid: userUuid,
    );

    return await result.when(
      (expense) {
        state = AsyncData([expense, ...previous]);
        ref.invalidate(reportControllerProvider);
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
    final previous = state.value ?? [];
    state = const AsyncLoading();
    final repository = ref.read(expenseRepositoryProvider);
    final result = await repository.updateExpense(
      id: id,
      amount: amount,
      date: date,
      description: description,
      categoryId: categoryId,
    );

    return await result.when(
      (updated) {
        final index = previous.indexWhere((e) => e.id == id);
        if (index != -1) {
          previous[index] = updated;
        }
        state = AsyncData(List.from(previous));
        ref.invalidate(reportControllerProvider);
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }

  /// Submits a new or updated expense.
  /// Returns true on success, false on error.
  Future<bool> submitExpense({
    required double amount,
    required int categoryId,
    required DateTime date,
    String? description,
    int? expenseId,
  }) async {
    if (expenseId != null) {
      return await updateExpense(
        id: expenseId,
        amount: amount,
        date: date,
        description: description,
        categoryId: categoryId,
      );
    }
    return await createExpense(
      amount: amount,
      date: date,
      description: description,
      categoryId: categoryId,
    );
  }

  Future<bool> deleteExpense({required int id}) async {
    final previous = state.value ?? [];

    state = const AsyncLoading();

    final repository = ref.read(expenseRepositoryProvider);

    final result = await repository.deleteExpense(id: id);

    return await result.when(
      (_) {
        state = AsyncData(previous.where((e) => e.id != id).toList());
        ref.invalidate(reportControllerProvider);
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }
}
