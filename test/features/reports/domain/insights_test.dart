import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/domain/insights.dart';
import 'package:flutter_test/flutter_test.dart';

MonthlyReport buildReport(List<CategoryBreakdown> breakdowns) {
  return MonthlyReport(
    total: breakdowns.fold<double>(0, (sum, b) => sum + b.amount),
    previousTotal: breakdowns.fold<double>(
      0,
      (sum, b) => sum + b.previousAmount,
    ),
    variation: 0,
    categoryBreakdowns: breakdowns,
    year: 2025,
    month: 7,
  );
}

CategoryBreakdown breakdown({
  required int categoryId,
  required String name,
  required double amount,
  double previousAmount = 0,
  bool isExpense = true,
}) {
  return CategoryBreakdown(
    categoryId: categoryId,
    categoryName: name,
    amount: amount,
    percentage: 100,
    previousAmount: previousAmount,
    isExpense: isExpense,
  );
}

void main() {
  group('generateInsights', () {
    test('+32% increase passes threshold 20', () {
      final report = buildReport([
        breakdown(
          categoryId: 1,
          name: 'Food',
          amount: 16500,
          previousAmount: 12500,
        ),
      ]);

      final insights = generateInsights(report: report);

      expect(insights, hasLength(1));
      final insight = insights.first;
      expect(insight.categoryId, 1);
      expect(insight.changePct, closeTo(32, 0.0001));
      expect(insight.isIncrease, isTrue);
      expect(insight.currentAmount, 16500);
      expect(insight.previousAmount, 12500);
      expect(insight.delta, 4000);
    });

    test('+15% below threshold 20 is excluded', () {
      final report = buildReport([
        breakdown(
          categoryId: 1,
          name: 'Food',
          amount: 11500,
          previousAmount: 10000,
        ),
      ]);

      expect(generateInsights(report: report), isEmpty);
    });

    test('previousAmount 0 with current > 0 excluded (no baseline)', () {
      final report = buildReport([
        breakdown(categoryId: 1, name: 'Food', amount: 5000),
      ]);

      expect(generateInsights(report: report), isEmpty);
    });

    test('current 0 with previous > 0 yields changePct -100', () {
      final report = buildReport([
        breakdown(categoryId: 1, name: 'Food', amount: 0, previousAmount: 800),
      ]);

      final insights = generateInsights(report: report);

      expect(insights, hasLength(1));
      expect(insights.first.changePct, -100);
      expect(insights.first.isIncrease, isFalse);
      expect(insights.first.delta, -800);
    });

    test('sorts qualifying categories by |delta| desc', () {
      final report = buildReport([
        breakdown(
          categoryId: 1,
          name: 'Small',
          amount: 1300,
          previousAmount: 1000, // delta 300
        ),
        breakdown(
          categoryId: 2,
          name: 'Big',
          amount: 6000,
          previousAmount: 1000, // delta 5000
        ),
        breakdown(
          categoryId: 3,
          name: 'Mid',
          amount: 3000,
          previousAmount: 1000, // delta 2000
        ),
      ]);

      final insights = generateInsights(report: report);

      expect(insights.map((i) => i.categoryId), [2, 3, 1]);
    });

    test('minDelta excludes pct-qualifying but small absolute delta', () {
      final report = buildReport([
        breakdown(
          categoryId: 1,
          name: 'Food',
          amount: 130,
          previousAmount: 100, // +30% but delta 30
        ),
      ]);

      expect(generateInsights(report: report, minDelta: 1000), isEmpty);
      expect(generateInsights(report: report), hasLength(1));
    });

    test('empty breakdowns yields empty list', () {
      expect(generateInsights(report: buildReport([])), isEmpty);
    });

    test('all previousAmount 0 yields empty list', () {
      final report = buildReport([
        breakdown(categoryId: 1, name: 'A', amount: 100),
        breakdown(categoryId: 2, name: 'B', amount: 500),
      ]);

      expect(generateInsights(report: report), isEmpty);
    });

    test('breakdowns with isExpense false are ignored', () {
      // Ahorro calificaría (+32%) pero no es gasto → fuera.
      final report = buildReport([
        breakdown(
          categoryId: 1,
          name: 'Ahorro',
          amount: 16500,
          previousAmount: 12500,
          isExpense: false,
        ),
        breakdown(
          categoryId: 2,
          name: 'Food',
          amount: 16500,
          previousAmount: 12500,
        ),
      ]);

      final insights = generateInsights(report: report);

      expect(insights, hasLength(1));
      expect(insights.single.categoryId, 2);
    });

    test('only non-expense breakdowns yields empty list', () {
      final report = buildReport([
        breakdown(
          categoryId: 1,
          name: 'Ahorro',
          amount: 5000,
          previousAmount: 1000,
          isExpense: false,
        ),
      ]);

      expect(generateInsights(report: report), isEmpty);
    });

    test('custom thresholdPct respected', () {
      final report = buildReport([
        breakdown(
          categoryId: 1,
          name: 'Food',
          amount: 16500,
          previousAmount: 12500, // +32%
        ),
        breakdown(
          categoryId: 2,
          name: 'Transport',
          amount: 8000,
          previousAmount: 5000, // +60%
        ),
      ]);

      final insights = generateInsights(report: report, thresholdPct: 50);

      expect(insights, hasLength(1));
      expect(insights.first.categoryId, 2);
      expect(insights.first.changePct, closeTo(60, 0.0001));
    });
  });
}
