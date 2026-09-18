import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/views/expense_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_helpers.dart';

final _testCategories = [
  Category(
    id: 1,
    name: 'Food',
    householdId: 1,
    createdAt: DateTime(2025),
    color: '#4CAF50',
    icon: '63046',
  ),
  Category(
    id: 2,
    name: 'Transport',
    householdId: 1,
    createdAt: DateTime(2025),
    color: '#2196F3',
    icon: '57681',
  ),
];

final _testExpenses = [
  Expense(
    id: 1,
    amount: 200,
    date: DateTime(2025, 7, 10),
    description: 'Groceries',
    householdId: 1,
    categoryId: 1,
    userUuid: 'user-1',
    createdAt: DateTime(2025, 7, 10),
  ),
  Expense(
    id: 2,
    amount: 50,
    date: DateTime(2025, 7, 12),
    description: 'Bus ticket',
    householdId: 1,
    categoryId: 2,
    userUuid: 'user-1',
    createdAt: DateTime(2025, 7, 12),
  ),
];

void main() {
  group('ExpenseListView', () {
    testWidgets('shows app bar with title', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gastos'), findsOneWidget);
    });

    testWidgets('displays category filter chip', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNWidgets(2));
      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Fecha'), findsOneWidget);
    });

    testWidgets('tapping category filter opens BottomSheet', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap category filter chip
      await tester.tap(find.text('Categoría'));
      await tester.pumpAndSettle();

      // BottomSheet should show all categories + "all" option
      expect(find.text('Todas las categorías'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('tapping date filter opens date range picker', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap date filter chip
      await tester.tap(find.text('Fecha'));
      await tester.pumpAndSettle();

      // Date range picker dialog should appear
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('shows expense items in list', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Bus ticket'), findsOneWidget);
    });

    testWidgets('shows empty state when no expenses', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              const AsyncData<List<Expense>>([]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyExpenses), findsOneWidget);
      expect(find.text('No hay gastos'), findsOneWidget);
    });

    testWidgets('shows FAB for creating new expense', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
