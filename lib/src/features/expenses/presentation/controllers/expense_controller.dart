import 'dart:async';

import 'package:biyuya/src/core/constants/app_constants.dart';
import 'package:biyuya/src/core/data/widget_daily_total_sync.dart';
import 'package:biyuya/src/core/network/connectivity_provider.dart';
import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/expense_totals.dart';
import 'package:biyuya/src/features/expenses/domain/services/featured_categories_calculator.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_list_controller.dart';
import 'package:biyuya/src/features/expenses/provider/expense_repository_provider.dart';
import 'package:biyuya/src/features/expenses/provider/expense_sync_providers.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/report_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'expense_controller.g.dart';

@Riverpod(keepAlive: true)
class ExpenseController extends _$ExpenseController {
  bool _isSubmitting = false;

  @override
  AsyncValue<List<Expense>> build() {
    ref.listen(isOnlineProvider, (previous, next) {
      if (next.value == true) {
        unawaited(retrySync());
      }
    });
    // Cold start: categories may still be loading when expenses are emitted,
    // so re-sync featured chips once they arrive.
    ref.listen<AsyncValue<List<Category>>>(categoryControllerProvider, (
      previous,
      next,
    ) {
      if (next.value == null) {
        return;
      }
      _syncFeaturedCategories(state.value ?? const <Expense>[]);
    });
    unawaited(Future.microtask(_loadExpenses));
    return const AsyncData([]);
  }

  /// Default load: current month only — monthly total, recent entries and
  /// today's total for home, plus the current month for debt settlement.
  /// Full history is deliberately not fetched here.
  Future<void> _loadExpenses() {
    final now = DateTime.now();
    return loadExpensesByMonth(year: now.year, month: now.month);
  }

  Future<void> loadExpensesByMonth({
    required int year,
    required int month,
  }) async {
    final session = ref.read(authSessionControllerProvider);
    final householdId = session.value?.householdId;

    if (householdId == null || householdId.isEmpty) {
      _emitExpenses(const []);
      return;
    }

    final pending = await ref.read(pendingExpenseStoreProvider).load();

    state = const AsyncLoading();
    final repository = ref.read(expenseRepositoryProvider);
    final result = await repository.getExpensesByMonth(
      householdId: int.parse(householdId),
      year: year,
      month: month,
    );
    result.when(
      (synced) => _merge(synced, pending),
      (failure) => _emitLoadFailure(failure, pending),
    );
  }

  String? get _userUuid {
    return ref.read(supabaseClientProvider).auth.currentUser?.id;
  }

  /// Single exit point: sets expenses state and syncs widget total.
  void _emitExpenses(List<Expense> expenses) {
    state = AsyncData(expenses);
    final now = DateTime.now();
    final categories =
        ref.read(categoryControllerProvider).value ?? const <Category>[];
    final todayTotal = sumCountableExpenses(
      expenses.where(
        (e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day,
      ),
      excludedCategoryIds(categories),
    );
    unawaited(WidgetDailyTotalSync.syncTotal(todayTotal));

    _syncFeaturedCategories(expenses);
  }

  /// Resolves the featured category chips from [expenses] and the currently
  /// loaded categories, then pushes them to the widget. Safe to call when
  /// categories are still loading (falls back to an empty list).
  void _syncFeaturedCategories(List<Expense> expenses) {
    final ids = topCategoryIdsLastWeek(
      expenses,
      DateTime.now(),
      // Explicit limit keeps the featured count visible at the call site.
      // ignore: avoid_redundant_argument_values
      limit: kFeaturedCategoryCount,
    );
    final categories =
        ref.read(categoryControllerProvider).value ?? const <Category>[];
    final byId = {for (final category in categories) category.id: category};
    final resolved = ids.map((id) => byId[id]).whereType<Category>().toList();
    // Fewer than 2 categories with recent activity: fall back to the first
    // loaded categories so the widget always has something to show.
    final featured = resolved.length < 2
        ? categories.take(kFeaturedCategoryCount).toList()
        : resolved;
    unawaited(WidgetDailyTotalSync.syncFeaturedCategories(featured));
  }

  /// Single failure exit point for load/reload paths: keep pending expenses
  /// visible when present, otherwise surface the error.
  void _emitLoadFailure(Object failure, List<Expense> pending) {
    if (pending.isNotEmpty) {
      _emitExpenses(pending);
    } else {
      state = AsyncError(failure, StackTrace.current);
    }
  }

  /// Concatenates synced + pending and emits them by date descending.
  /// Copies first so the inputs are never mutated.
  void _merge(List<Expense> synced, List<Expense> pending) {
    final merged = [...synced, ...pending]
      ..sort((a, b) => b.date.compareTo(a.date));
    _emitExpenses(merged);
  }

  /// Reloads the outbox, refreshes the current-month network list and
  /// re-merges. Keeps the previous state visible instead of flashing loading.
  Future<void> _reloadMerge() async {
    final pending = await ref.read(pendingExpenseStoreProvider).load();
    final session = ref.read(authSessionControllerProvider);
    final householdId = session.value?.householdId;

    if (householdId == null || householdId.isEmpty) {
      _emitExpenses(pending);
      return;
    }

    final now = DateTime.now();
    final result = await ref
        .read(expenseRepositoryProvider)
        .getExpensesByMonth(
          householdId: int.parse(householdId),
          year: now.year,
          month: now.month,
        );
    result.when(
      (synced) => _merge(synced, pending),
      (failure) => _emitLoadFailure(failure, pending),
    );
  }

  Future<void> _flushAndRemerge() async {
    await ref.read(expenseSyncServiceProvider).flush();
    await _reloadMerge();
  }

  /// Single choke point for derived state: reports + the paginated list view.
  /// Without invalidating [expenseListControllerProvider] the list view keeps
  /// its stale items after a mutation (its initial-load guard skips refresh).
  void _invalidateDerived() {
    ref
      ..invalidate(reportControllerProvider)
      ..invalidate(expenseListControllerProvider);
  }

  /// Flushes the outbox, refreshes state and reports.
  Future<void> retrySync() async {
    await ref.read(expenseSyncServiceProvider).flush();
    await _reloadMerge();
    _invalidateDerived();
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

    final clientId = const Uuid().v4();
    final pendingExpense = Expense.pending(
      amount: amount,
      date: date,
      householdId: int.parse(householdId),
      categoryId: categoryId,
      clientId: clientId,
      description: description,
      userUuid: userUuid,
      userName: session.value?.name,
    );

    await ref.read(pendingExpenseStoreProvider).add(pendingExpense);
    _emitExpenses([pendingExpense, ...previous]);
    _invalidateDerived();

    unawaited(_flushAndRemerge());
    return true;
  }

  Future<bool> discardPending(String clientId) async {
    await ref.read(pendingExpenseStoreProvider).remove(clientId);
    await _reloadMerge();
    _invalidateDerived();
    return true;
  }

  Future<bool> updateExpense({
    required int id,
    required double amount,
    required DateTime date,
    required int categoryId,
    String? description,
  }) async {
    final previous = state.value ?? [];
    final existingIndex = previous.indexWhere((e) => e.id == id);
    if (existingIndex != -1 &&
        previous[existingIndex].syncStatus == ExpenseSyncStatus.pending) {
      // ponytail: update offline no requerido
      return false;
    }

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
        final updatedList = List<Expense>.from(previous);
        _emitExpenses(updatedList);
        _invalidateDerived();
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
    // ponytail: guard controller-level + AsyncLoading habilita el disable existente del form
    if (_isSubmitting) {
      return false;
    }
    _isSubmitting = true;
    try {
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
    } finally {
      _isSubmitting = false;
    }
  }

  Future<bool> deleteExpense({required int id}) async {
    final previous = state.value ?? [];
    final index = previous.indexWhere((e) => e.id == id);

    // Pending expense never hit the server: just drop it from the outbox.
    if (index != -1 &&
        previous[index].syncStatus == ExpenseSyncStatus.pending) {
      final clientId = previous[index].clientId;
      if (clientId != null) {
        return await discardPending(clientId);
      }
      _emitExpenses(previous.where((e) => e.id != id).toList());
      _invalidateDerived();
      return true;
    }

    state = const AsyncLoading();
    final repository = ref.read(expenseRepositoryProvider);
    final result = await repository.deleteExpense(id: id);

    return await result.when(
      (_) {
        final remaining = previous.where((e) => e.id != id).toList();
        _emitExpenses(remaining);
        _invalidateDerived();
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }
}
