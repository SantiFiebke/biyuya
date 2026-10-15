import 'package:biyuya/src/features/reports/domain/entities/weekly_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeeklyReport', () {
    WeeklyReport makeReport({
      double total = 1000,
      double previousWeekTotal = 800,
      double variation = 25,
    }) {
      return WeeklyReport(
        weekStart: DateTime(2026, 9, 7),
        weekEnd: DateTime(2026, 9, 14),
        total: total,
        previousWeekTotal: previousWeekTotal,
        variation: variation,
        breakdowns: const [],
        year: 2026,
        week: 36,
      );
    }

    test('creates correctly with all fields', () {
      final report = makeReport();

      expect(report.weekStart, DateTime(2026, 9, 7));
      expect(report.weekEnd, DateTime(2026, 9, 14));
      expect(report.total, 1000);
      expect(report.previousWeekTotal, 800);
      expect(report.variation, 25.0);
      expect(report.breakdowns, isEmpty);
      expect(report.year, 2026);
      expect(report.week, 36);
    });

    test('hasPreviousData is true when previousWeekTotal > 0', () {
      expect(makeReport().hasPreviousData, isTrue);
    });

    test('hasPreviousData is false when previousWeekTotal is 0', () {
      expect(makeReport(previousWeekTotal: 0).hasPreviousData, isFalse);
    });

    test('isIncrease is true when variation > 0', () {
      expect(makeReport().isIncrease, isTrue);
    });

    test('isIncrease is false when variation is 0', () {
      expect(makeReport(variation: 0).isIncrease, isFalse);
    });

    test('isIncrease is false when variation is negative', () {
      expect(makeReport(variation: -25).isIncrease, isFalse);
    });

    test('supports equality via Equatable', () {
      expect(makeReport(), equals(makeReport()));
    });
  });
}
