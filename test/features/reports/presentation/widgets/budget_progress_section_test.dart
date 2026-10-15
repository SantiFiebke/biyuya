import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/budget_progress_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_helpers.dart';

CategoryBreakdown makeBreakdown({
  int categoryId = 1,
  String categoryName = 'Comida',
  double amount = 300,
  double? budgetAmount,
  bool isExpense = true,
}) {
  return CategoryBreakdown(
    categoryId: categoryId,
    categoryName: categoryName,
    amount: amount,
    percentage: 60,
    categoryColor: '#4CAF50',
    categoryIcon: '63046',
    budgetAmount: budgetAmount,
    isExpense: isExpense,
  );
}

void main() {
  group('BudgetProgressSection', () {
    testWidgets('renders progress percentage and available amount', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: BudgetProgressSection(
            breakdowns: [makeBreakdown(budgetAmount: 500)],
          ),
        ),
      );

      expect(find.text('Presupuestos'), findsOneWidget);
      expect(find.byType(BudgetProgressRow), findsOneWidget);
      // 300 / 500 = 60%.
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('Disponible'), findsOneWidget);
    });

    testWidgets('renders Excedido and >100% when over budget', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: BudgetProgressSection(
            breakdowns: [makeBreakdown(amount: 600, budgetAmount: 500)],
          ),
        ),
      );

      expect(find.text('120%'), findsOneWidget);
      expect(find.text('Excedido'), findsOneWidget);
      expect(find.text('Disponible'), findsNothing);
    });

    testWidgets('skips categories with null or zero budget', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: BudgetProgressSection(
            breakdowns: [
              makeBreakdown(amount: 100), // null budget
              makeBreakdown(
                categoryId: 2,
                categoryName: 'Transporte',
                amount: 50,
                budgetAmount: 0, // cero no cuenta
              ),
              makeBreakdown(
                categoryId: 3,
                categoryName: 'Ahorro',
                amount: 500,
                budgetAmount: 1000,
                isExpense: false, // no-gasto se ignora
              ),
              makeBreakdown(
                categoryId: 4,
                categoryName: 'Ocio',
                amount: 200,
                budgetAmount: 400,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(BudgetProgressRow), findsOneWidget);
      expect(find.text('Ocio'), findsOneWidget);
      expect(find.text('Comida'), findsNothing);
      expect(find.text('Ahorro'), findsNothing);
    });

    testWidgets('renders SizedBox.shrink when no category has budget', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: BudgetProgressSection(
            breakdowns: [
              makeBreakdown(amount: 100),
              makeBreakdown(categoryId: 2, amount: 200),
            ],
          ),
        ),
      );

      expect(find.byType(BudgetProgressRow), findsNothing);
      expect(find.text('Presupuestos'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
