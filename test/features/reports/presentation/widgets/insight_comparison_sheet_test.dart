import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/reports/domain/entities/insight.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/insight_comparison_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _testInsight = Insight(
  categoryId: 1,
  categoryName: 'Comida',
  // Montos del insight distintos a los subtotales reales de las fixtures
  // (600 / 200) para poder distinguir header de secciones en los asserts.
  currentAmount: 610,
  previousAmount: 210,
  changePct: 200,
  isIncrease: true,
  categoryColor: '#FF5722',
  categoryIcon: '57810',
);

Expense _expense({
  required int id,
  required double amount,
  required String description,
  required DateTime date,
  int categoryId = 1,
}) {
  return Expense(
    id: id,
    amount: amount,
    description: description,
    date: date,
    householdId: 1,
    categoryId: categoryId,
    createdAt: date,
  );
}

/// Mes actual: sep/2026 (año 2026, mes 9). Mes anterior: ago/2026.
///
/// Promedio previo = (150 + 50) / 2 = 100 → umbral `grande` = 200.
final List<Expense> _testExpenses = [
  // Actual: descripción nueva y monto >= 200 → nuevo + grande.
  _expense(
    id: 10,
    amount: 500,
    description: 'Cine',
    date: DateTime(2026, 9, 5),
  ),
  // Actual: descripción coincide con previa y monto < 200 → sin etiquetas.
  _expense(
    id: 11,
    amount: 100,
    description: 'Almuerzo',
    date: DateTime(2026, 9, 12),
  ),
  // Previos: alimentan promedio y se listan sin chips.
  _expense(
    id: 12,
    amount: 150,
    description: 'Almuerzo',
    date: DateTime(2026, 8, 10),
  ),
  _expense(
    id: 13,
    amount: 50,
    description: 'Taxi',
    date: DateTime(2026, 8, 20),
  ),
  // Otra categoría: fuera del desglose del insight.
  _expense(
    id: 14,
    amount: 9999,
    description: 'Otra categoría',
    date: DateTime(2026, 9),
    categoryId: 2,
  ),
];

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

/// Montos de los [AmountText] dentro de la fila más cercana a [anchor].
List<double> amountsNear(WidgetTester tester, Finder anchor) {
  final row = find.ancestor(of: anchor, matching: find.byType(Row)).first;
  return tester
      .widgetList<AmountText>(
        find.descendant(of: row, matching: find.byType(AmountText)),
      )
      .map((w) => w.amount)
      .toList();
}

void main() {
  group('InsightComparisonSheet', () {
    testWidgets('renders header with category name and both month subtotals', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithExpenses(
          const InsightComparisonSheet(
            insight: _testInsight,
            year: 2026,
            month: 9,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comida'), findsOneWidget);

      // Header: "Este mes X vs Y" con los montos del insight.
      expect(find.text(' vs '), findsOneWidget);
      expect(amountsNear(tester, find.text(' vs ')), [
        _testInsight.currentAmount,
        _testInsight.previousAmount,
      ]);

      // Subtotales por sección (solo gastos de la categoría).
      expect(find.text('Este mes'), findsOneWidget);
      expect(amountsNear(tester, find.text('Este mes')), [600]);
      expect(find.text('Mes anterior'), findsOneWidget);
      expect(amountsNear(tester, find.text('Mes anterior')), [200]);
    });

    testWidgets('shows nuevo/grande chips on tagged current-month expense', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithExpenses(
          const InsightComparisonSheet(
            insight: _testInsight,
            year: 2026,
            month: 9,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cineTile = find
          .ancestor(of: find.text('Cine'), matching: find.byType(ListTile))
          .first;
      expect(
        find.descendant(of: cineTile, matching: find.text('Nuevo')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: cineTile, matching: find.text('Grande')),
        findsOneWidget,
      );

      // Almuerzo coincide con el mes anterior y no supera 2x → sin chips.
      final almuerzoTiles = find.ancestor(
        of: find.text('Almuerzo'),
        matching: find.byType(ListTile),
      );
      expect(almuerzoTiles, findsNWidgets(2));
      expect(find.text('Nuevo'), findsOneWidget);
      expect(find.text('Grande'), findsOneWidget);
    });

    testWidgets('previous-month section lists expenses without chips', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithExpenses(
          const InsightComparisonSheet(
            insight: _testInsight,
            year: 2026,
            month: 9,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Taxi solo existe en el mes anterior y se lista normal.
      expect(find.text('Taxi'), findsOneWidget);
      final taxiTile = find
          .ancestor(of: find.text('Taxi'), matching: find.byType(ListTile))
          .first;
      expect(
        find.descendant(of: taxiTile, matching: find.text('Nuevo')),
        findsNothing,
      );
      expect(
        find.descendant(of: taxiTile, matching: find.text('Grande')),
        findsNothing,
      );

      // Almuerzo previo tampoco lleva chips.
      final almuerzoTiles = find.ancestor(
        of: find.text('Almuerzo'),
        matching: find.byType(ListTile),
      );
      final previousAlmuerzo = almuerzoTiles.at(1);
      expect(
        find.descendant(of: previousAlmuerzo, matching: find.text('Nuevo')),
        findsNothing,
      );
      expect(
        find.descendant(of: previousAlmuerzo, matching: find.text('Grande')),
        findsNothing,
      );
    });

    testWidgets('shows empty message when previous month has no expenses', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithExpenses(
          const InsightComparisonSheet(
            insight: _testInsight,
            year: 2026,
            month: 9,
          ),
          expenses: _testExpenses.where((e) => e.date.month == 9).toList(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin gastos el mes anterior'), findsOneWidget);
      expect(find.text('Taxi'), findsNothing);
    });

    testWidgets('show presents the sheet from a context', (tester) async {
      await tester.pumpWidget(
        wrapWithExpenses(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => InsightComparisonSheet.show(
                context,
                insight: _testInsight,
                year: 2026,
                month: 9,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Comida'), findsOneWidget);
      expect(find.text('Mes anterior'), findsOneWidget);
    });
  });
}
