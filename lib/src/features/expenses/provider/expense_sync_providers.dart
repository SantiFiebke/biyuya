import 'package:biyuya/src/features/expenses/data/local/pending_expense_store.dart';
import 'package:biyuya/src/features/expenses/data/sync/expense_sync_service.dart';
import 'package:biyuya/src/features/expenses/provider/expense_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expense_sync_providers.g.dart';

@riverpod
PendingExpenseStore pendingExpenseStore(Ref ref) => const PendingExpenseStore();

@riverpod
ExpenseSyncService expenseSyncService(Ref ref) => ExpenseSyncService(
  ref.watch(expenseRepositoryProvider),
  ref.watch(pendingExpenseStoreProvider),
);
