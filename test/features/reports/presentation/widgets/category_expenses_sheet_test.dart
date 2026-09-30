import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/provider/expenses_by_month_provider.dart';
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

const _servicioBreakdown = CategoryBreakdown(
  categoryId: 1,
  categoryName: 'Servicio',
  amount: 7500,
  percentage: 100,
  categoryColor: '#4CAF50',
  categoryIcon: '57810',
);

final _augustExpense = Expense(
  id: 20,
  amount: 2500,
  date: DateTime(2026, 8, 12),
  householdId: 1,
  categoryId: 1,
  description: 'Luz agosto',
  createdAt: DateTime(2026, 8, 12),
);

final _septemberExpense = Expense(
  id: 21,
  amount: 5000,
  date: DateTime(2026, 9, 12),
  householdId: 1,
  categoryId: 1,
  description: 'Luz septiembre',
  createdAt: DateTime(2026, 9, 12),
);

Widget wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

/// Harness: overrides the month-scoped source the sheet actually reads
/// ([expensesByMonthProvider]) for every requested (year, month), plus the
/// home source ([expenseControllerProvider]) with the whole pool — a
/// regression back to the home source would leak the other month's rows.
Widget wrapWithExpenses(
  Widget child, {
  List<Expense>? expenses,
  List<({int year, int month})> months = const [(year: 2026, month: 9)],
}) {
  final pool = expenses ?? _testExpenses;
  return ProviderScope(
    overrides: [
      expenseControllerProvider.overrideWithValue(AsyncData(pool)),
      for (final m in months)
        expensesByMonthProvider(year: m.year, month: m.month).overrideWith(
          (ref) async => pool
              .where((e) => e.date.year == m.year && e.date.month == m.month)
              .toList(),
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

    testWidgets('renders only the requested month rows and its header total', (
      tester,
    ) async {
      // Regression: the sheet must read expensesByMonthProvider(2026, 8)
      // instead of the full home list — the September row (and total) must
      // not leak into an August sheet.
      await tester.pumpWidget(
        wrapWithExpenses(
          const CategoryExpensesSheet(
            breakdown: _servicioBreakdown,
            year: 2026,
            month: 8,
          ),
          expenses: [_augustExpense, _septemberExpense],
          months: [(year: 2026, month: 8)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Servicio'), findsOneWidget);
      expect(find.text('Luz agosto'), findsOneWidget);
      // Header total + row trailing amount, both '$2.500'.
      expect(find.textContaining('2.500'), findsNWidgets(2));

      expect(find.text('Luz septiembre'), findsNothing);
      expect(find.textContaining('5.000'), findsNothing);
    });
  });
}
