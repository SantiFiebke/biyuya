import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/expense_merge.dart';
import 'package:biyuya/src/features/expenses/provider/expense_repository_provider.dart';
import 'package:biyuya/src/features/expenses/provider/expense_sync_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expenses_by_month_provider.g.dart';

@riverpod
Future<List<Expense>> expensesByMonth(
  Ref ref, {
  required int year,
  required int month,
}) async {
  final householdId = ref
      .watch(authSessionControllerProvider)
      .value
      ?.householdIdValue;
  if (householdId == null) {
    return const <Expense>[];
  }

  final pending = await ref.watch(pendingExpenseStoreProvider).load();
  final pendingForMonth = expensesForMonth(pending, year, month);

  final result = await ref
      .watch(expenseRepositoryProvider)
      .getExpensesByMonth(householdId: householdId, year: year, month: month);

  return result.when<List<Expense>>(
    (synced) => mergeExpensesByDateDesc(synced, pendingForMonth),
    // Offline: keep month-scoped outbox entries visible instead of erroring.
    (_) => pendingForMonth,
  );
}
