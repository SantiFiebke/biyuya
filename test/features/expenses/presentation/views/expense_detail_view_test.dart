import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/views/expense_detail_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

final _pendingExpense = Expense(
  id: 2,
  amount: 50,
  date: DateTime(2025, 7, 12),
  description: 'Pending',
  householdId: 1,
  categoryId: 1,
  userUuid: 'user-1',
  clientId: 'client-2',
  syncStatus: ExpenseSyncStatus.pending,
  createdAt: DateTime(2025, 7, 12),
);

final _syncedExpense = Expense(
  id: 1,
  amount: 200,
  date: DateTime(2025, 7, 10),
  description: 'Synced',
  householdId: 1,
  categoryId: 1,
  userUuid: 'user-1',
  createdAt: DateTime(2025, 7, 10),
);

List<Override> _overrides() => [
  categoryControllerProvider.overrideWithValue(
    const AsyncData<List<Category>>([]),
  ),
];

void main() {
  group('ExpenseDetailView pending actions', () {
    testWidgets('shows "Descartar" action for a pending expense', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: ExpenseDetailView(expense: _pendingExpense),
          overrides: _overrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Descartar'), findsOneWidget);
      expect(find.byTooltip('Editar'), findsNothing);
    });

    testWidgets('shows "Editar" and no "Descartar" for a synced expense', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: ExpenseDetailView(expense: _syncedExpense),
          overrides: _overrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Editar'), findsOneWidget);
      expect(find.byTooltip('Descartar'), findsNothing);
    });
  });
}
