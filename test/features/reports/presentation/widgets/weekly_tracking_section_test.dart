import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/features/reports/domain/entities/weekly_category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/weekly_report.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/weekly_tracking_section.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

WeeklyCategoryBreakdown makeBreakdown({
  required double amount,
  required double weeklyBudget,
  int categoryId = 1,
  String categoryName = 'Comida',
  WeeklyBudgetStatus status = WeeklyBudgetStatus.ok,
}) {
  return WeeklyCategoryBreakdown(
    categoryId: categoryId,
    categoryName: categoryName,
    categoryColor: '#4CAF50',
    categoryIcon: '63046',
    amount: amount,
    weeklyBudget: weeklyBudget,
    deviation: amount - weeklyBudget,
    status: status,
  );
}

WeeklyReport makeWeeklyReport({
  double total = 1000,
  double previousWeekTotal = 0,
  double variation = 0,
  List<WeeklyCategoryBreakdown> breakdowns = const [],
  DateTime? weekStart,
  DateTime? weekEnd,
  int year = 2025,
  int week = 28,
}) {
  return WeeklyReport(
    weekStart: weekStart ?? DateTime(2025, 7, 7),
    // weekEnd exclusivo (lunes siguiente).
    weekEnd: weekEnd ?? DateTime(2025, 7, 14),
    total: total,
    previousWeekTotal: previousWeekTotal,
    variation: variation,
    breakdowns: breakdowns,
    year: year,
    week: week,
  );
}

void main() {
  group('WeeklyTrackingSection', () {
    testWidgets('renders week number and date range', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: WeeklyTrackingSection(report: makeWeeklyReport())),
      );

      expect(find.text('Semana 28'), findsOneWidget);
      // weekEnd(14/07) es exclusivo → último día real 13/07.
      expect(find.text('07/07 – 13/07'), findsOneWidget);
    });

    testWidgets('renders total from report', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: WeeklyTrackingSection(report: makeWeeklyReport(total: 2500)),
        ),
      );

      final amount = tester.widget<AmountText>(
        find.descendant(
          of: find.byType(WeeklySummaryCard),
          matching: find.byType(AmountText),
        ),
      );
      expect(amount.amount, 2500);
    });

    testWidgets('renders the correct semaphore for each status', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: WeeklyTrackingSection(
            report: makeWeeklyReport(
              breakdowns: [
                makeBreakdown(
                  categoryName: 'Ok',
                  amount: 100,
                  weeklyBudget: 200,
                ),
                makeBreakdown(
                  categoryId: 2,
                  categoryName: 'Warn',
                  amount: 180,
                  weeklyBudget: 200,
                  status: WeeklyBudgetStatus.warning,
                ),
                makeBreakdown(
                  categoryId: 3,
                  categoryName: 'Over',
                  amount: 300,
                  weeklyBudget: 200,
                  status: WeeklyBudgetStatus.exceeded,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('🟢'), findsOneWidget);
      expect(find.text('🟡'), findsOneWidget);
      expect(find.text('🔴'), findsOneWidget);
    });

    testWidgets('renders one card per breakdown', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: WeeklyTrackingSection(
            report: makeWeeklyReport(
              breakdowns: [
                makeBreakdown(amount: 100, weeklyBudget: 200),
                makeBreakdown(
                  categoryId: 2,
                  categoryName: 'Transporte',
                  amount: 50,
                  weeklyBudget: 100,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(WeeklyCategoryCard), findsNWidgets(2));
    });
  });
}
