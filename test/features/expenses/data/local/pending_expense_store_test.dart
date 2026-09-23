import 'package:biyuya/src/features/expenses/data/local/pending_expense_store.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = PendingExpenseStore();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Expense pendingExpense({
    required String clientId,
    double amount = 100.0,
    int householdId = 1,
    int categoryId = 1,
    String? description = 'Test expense',
  }) {
    return Expense.pending(
      amount: amount,
      date: DateTime(2025, 7, 15),
      householdId: householdId,
      categoryId: categoryId,
      clientId: clientId,
      description: description,
    );
  }

  group('PendingExpenseStore', () {
    test('load returns empty list when nothing stored', () async {
      expect(await store.load(), isEmpty);
    });

    test('add persists expense and load recovers it as pending', () async {
      final expense = pendingExpense(clientId: 'client-1', amount: 42.5);

      await store.add(expense);
      final loaded = await store.load();

      expect(loaded, hasLength(1));
      expect(loaded.single.clientId, 'client-1');
      expect(loaded.single.syncStatus, ExpenseSyncStatus.pending);
      expect(loaded.single.amount, 42.5);
    });

    test('add appends to existing pending expenses', () async {
      await store.add(pendingExpense(clientId: 'client-1'));
      await store.add(pendingExpense(clientId: 'client-2'));

      final loaded = await store.load();
      expect(loaded.map((e) => e.clientId), ['client-1', 'client-2']);
    });

    test('remove deletes only the matching clientId', () async {
      await store.add(pendingExpense(clientId: 'client-1'));
      await store.add(pendingExpense(clientId: 'client-2'));
      await store.add(pendingExpense(clientId: 'client-3'));

      await store.remove('client-2');

      final loaded = await store.load();
      expect(loaded.map((e) => e.clientId), ['client-1', 'client-3']);
    });

    test('remove unknown clientId leaves store untouched', () async {
      await store.add(pendingExpense(clientId: 'client-1'));

      await store.remove('missing');

      expect(await store.load(), hasLength(1));
    });

    test('clear empties the store', () async {
      await store.add(pendingExpense(clientId: 'client-1'));
      await store.add(pendingExpense(clientId: 'client-2'));

      await store.clear();

      expect(await store.load(), isEmpty);
    });

    test('JSON round-trip preserves all fields', () async {
      final expense = pendingExpense(
        clientId: 'client-round-trip',
        amount: 1234.56,
        householdId: 7,
        categoryId: 3,
        description: 'Groceries',
      );

      await store.save([expense]);
      final loaded = (await store.load()).single;

      expect(loaded.id, expense.id);
      expect(loaded.amount, expense.amount);
      expect(loaded.date, expense.date);
      expect(loaded.description, expense.description);
      expect(loaded.householdId, expense.householdId);
      expect(loaded.categoryId, expense.categoryId);
      expect(loaded.userUuid, expense.userUuid);
      expect(loaded.userName, expense.userName);
      expect(loaded.createdAt, expense.createdAt);
      expect(loaded.clientId, expense.clientId);
      expect(loaded.syncStatus, expense.syncStatus);
    });

    test('save overwrites previously stored list', () async {
      await store.add(pendingExpense(clientId: 'old'));

      await store.save([
        pendingExpense(clientId: 'new-1'),
        pendingExpense(clientId: 'new-2'),
      ]);

      final loaded = await store.load();
      expect(loaded.map((e) => e.clientId), ['new-1', 'new-2']);
    });
  });
}
