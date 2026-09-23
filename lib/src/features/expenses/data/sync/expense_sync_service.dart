import 'package:biyuya/src/features/expenses/data/local/pending_expense_store.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:multiple_result/multiple_result.dart';

/// Result of a single [ExpenseSyncService.flush] run.
class SyncSummary {
  const SyncSummary({this.synced = 0, this.failed = 0, this.errors = const []});

  final int synced;
  final int failed;
  final List<String> errors;
}

/// Flushes the pending-expense outbox to the backend.
///
/// ponytail: no attempt tracking/backoff — every trigger retries the whole
/// queue. Add per-item attempts + exponential backoff if a poison item ever
/// blocks the queue in practice.
class ExpenseSyncService {
  ExpenseSyncService(this._repository, this._store);

  final ExpenseRepositoryBase _repository;
  final PendingExpenseStore _store;

  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  Future<SyncSummary> flush() async {
    if (_isSyncing) {
      return const SyncSummary();
    }
    _isSyncing = true;
    try {
      final pending = await _store.load();
      var synced = 0;
      final errors = <String>[];

      for (final expense in pending) {
        final clientId = expense.clientId;
        final userUuid = expense.userUuid;
        if (clientId == null || userUuid == null) {
          errors.add('Gasto sin clientId/userUuid, se mantiene en cola');
          continue;
        }

        final result = await _repository.createExpense(
          amount: expense.amount,
          date: expense.date,
          householdId: expense.householdId,
          categoryId: expense.categoryId,
          userUuid: userUuid,
          description: expense.description,
          clientId: clientId,
        );

        switch (result) {
          case Success():
            await _store.remove(clientId);
            synced++;
          case Error(:final error):
            errors.add(error.message);
        }
      }

      return SyncSummary(synced: synced, failed: errors.length, errors: errors);
    } finally {
      _isSyncing = false;
    }
  }
}
