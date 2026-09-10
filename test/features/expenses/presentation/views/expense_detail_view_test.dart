import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/views/expense_detail_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _testExpense = Expense(
  id: 42,
  amount: 150.75,
  date: DateTime(2025, 6, 15),
  description: 'Groceries',
  householdId: 1,
  categoryId: 2,
  userUuid: 'user-1',
  createdAt: DateTime(2025, 6, 15),
);

final _testCategories = [
  Category(
    id: 2,
    name: 'Transport',
    householdId: 1,
    createdAt: DateTime(2025),
    color: '#2196F3',
    icon: '57681',
  ),
];

Widget wrap(Widget child) {
  return ProviderScope(
    overrides: [
      categoryControllerProvider.overrideWithValue(
        AsyncData<List<Category>>(_testCategories),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('ExpenseDetailView', () {
    testWidgets('shows app bar with title', (tester) async {
      await tester.pumpWidget(wrap(ExpenseDetailView(expense: _testExpense)));
      await tester.pumpAndSettle();

      expect(find.text('Detalle del gasto'), findsOneWidget);
    });

    testWidgets('displays expense amount', (tester) async {
      await tester.pumpWidget(wrap(ExpenseDetailView(expense: _testExpense)));
      await tester.pumpAndSettle();

      // 150.75 formatted as currency
      expect(find.textContaining('150'), findsOneWidget);
    });

    testWidgets('displays description', (tester) async {
      await tester.pumpWidget(wrap(ExpenseDetailView(expense: _testExpense)));
      await tester.pumpAndSettle();

      expect(find.text('Descripción'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
    });

    testWidgets('displays category name', (tester) async {
      await tester.pumpWidget(wrap(ExpenseDetailView(expense: _testExpense)));
      await tester.pumpAndSettle();

      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('displays formatted date', (tester) async {
      await tester.pumpWidget(wrap(ExpenseDetailView(expense: _testExpense)));
      await tester.pumpAndSettle();

      expect(find.text('Fecha'), findsOneWidget);
      expect(find.text('15/06/2025'), findsOneWidget);
    });

    testWidgets('displays user uuid', (tester) async {
      await tester.pumpWidget(wrap(ExpenseDetailView(expense: _testExpense)));
      await tester.pumpAndSettle();

      expect(find.text('Registrado por'), findsOneWidget);
      expect(find.text('user-1'), findsOneWidget);
    });

    testWidgets('edit button exists in app bar', (tester) async {
      await tester.pumpWidget(wrap(ExpenseDetailView(expense: _testExpense)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('shows "Sin descripción" when description is null', (
      tester,
    ) async {
      final expenseNoDesc = Expense(
        id: 1,
        amount: 100,
        date: DateTime(2025),
        householdId: 1,
        categoryId: 2,
        userUuid: 'user-1',
        createdAt: DateTime(2025),
      );
      await tester.pumpWidget(wrap(ExpenseDetailView(expense: expenseNoDesc)));
      await tester.pumpAndSettle();

      expect(find.text('Sin descripción'), findsOneWidget);
    });

    testWidgets('shows "Sin categoría" when category not found', (
      tester,
    ) async {
      final expenseOtherCategory = Expense(
        id: 1,
        amount: 100,
        date: DateTime(2025),
        description: 'Test',
        householdId: 1,
        categoryId: 999, // No matching category
        userUuid: 'user-1',
        createdAt: DateTime(2025),
      );
      await tester.pumpWidget(
        wrap(ExpenseDetailView(expense: expenseOtherCategory)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin categoría'), findsOneWidget);
    });
  });
}
