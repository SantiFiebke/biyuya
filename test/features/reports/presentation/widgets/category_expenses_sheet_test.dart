import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/presentation/views/report_view.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/category_expenses_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _testBreakdown = CategoryBreakdown(
  categoryId: 1,
  categoryName: 'Comida',
  amount: 1500,
  percentage: 35.5,
  categoryColor: '#FF5722',
  categoryIcon: '57810', // Icons.restaurant (0xe532)
);

final _testExpenses = [
  Expense(
    id: 1,
    amount: 500,
    date: DateTime(2026, 9, 10),
    householdId: 1,
    categoryId: 1,
    description: 'Almuerzo',
    createdAt: DateTime(2026, 9, 10),
  ),
  Expense(
    id: 2,
    amount: 1000,
    date: DateTime(2026, 9, 15),
    householdId: 1,
    categoryId: 1,
    description: 'Cena',
    createdAt: DateTime(2026, 9, 15),
  ),
];

Widget wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Widget wrapWithExpenses(Widget child, {List<Expense>? expenses}) {
  return ProviderScope(
    overrides: [
      expenseControllerProvider.overrideWithValue(
        AsyncData(expenses ?? _testExpenses),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('CategoryBreakdownTile', () {
    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          CategoryBreakdownTile(
            breakdown: _testBreakdown,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comida'), findsOneWidget);

      await tester.tap(find.byType(CategoryBreakdownTile));
      expect(tapped, isTrue);
    });
  });

  group('CategoryExpensesSheet', () {
    testWidgets('shows category name in header', (tester) async {
      await tester.pumpWidget(
        wrapWithExpenses(
          const CategoryExpensesSheet(
            breakdown: _testBreakdown,
            year: 2026,
            month: 9,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comida'), findsOneWidget);
    });

    testWidgets('shows filtered expenses', (tester) async {
      await tester.pumpWidget(
        wrapWithExpenses(
          const CategoryExpensesSheet(
            breakdown: _testBreakdown,
            year: 2026,
            month: 9,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Almuerzo'), findsOneWidget);
      expect(find.text('Cena'), findsOneWidget);
    });
  });
}
