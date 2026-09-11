import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthlyReport', () {
    test('creates correctly with all fields', () {
      final breakdowns = [
        const CategoryBreakdown(
          categoryId: 1,
          categoryName: 'Food',
          amount: 500,
          percentage: 50,
          categoryColor: '#FF0000',
          categoryIcon: '12345',
        ),
      ];

      final report = MonthlyReport(
        total: 1000,
        previousTotal: 800,
        variation: 25,
        categoryBreakdowns: breakdowns,
        year: 2025,
        month: 7,
      );

      expect(report.total, 1000);
      expect(report.previousTotal, 800);
      expect(report.variation, 25.0);
      expect(report.categoryBreakdowns, hasLength(1));
      expect(report.year, 2025);
      expect(report.month, 7);
    });

    test('hasPreviousData returns true when previousTotal > 0', () {
      const report = MonthlyReport(
        total: 1000,
        previousTotal: 800,
        variation: 25,
        categoryBreakdowns: [],
        year: 2025,
        month: 7,
      );

      expect(report.hasPreviousData, isTrue);
    });

    test('hasPreviousData returns false when previousTotal is 0', () {
      const report = MonthlyReport(
        total: 1000,
        previousTotal: 0,
        variation: 0,
        categoryBreakdowns: [],
        year: 2025,
        month: 1,
      );

      expect(report.hasPreviousData, isFalse);
    });

    test('isIncrease returns true when variation > 0', () {
      const report = MonthlyReport(
        total: 1000,
        previousTotal: 800,
        variation: 25,
        categoryBreakdowns: [],
        year: 2025,
        month: 7,
      );

      expect(report.isIncrease, isTrue);
    });

    test('isIncrease returns false when variation <= 0', () {
      const report = MonthlyReport(
        total: 600,
        previousTotal: 800,
        variation: -25,
        categoryBreakdowns: [],
        year: 2025,
        month: 7,
      );

      expect(report.isIncrease, isFalse);
    });
  });
}
