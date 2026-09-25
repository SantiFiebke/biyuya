import 'package:biyuya/src/features/reports/domain/month_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('projectMonthEnd', () {
    test('scales mid-month spend to full month', () {
      // 15000 / 24 * 30 = 18750 (exact in double: 15000/24 = 625)
      final result = projectMonthEnd(
        spentSoFar: 15000,
        referenceDate: DateTime(2026, 9, 24),
      );

      expect(result, 18750);
    });

    test('day 1 projects spend over entire month', () {
      // 31-day month (July), day 1: 100 / 1 * 31 = 3100
      final result = projectMonthEnd(
        spentSoFar: 100,
        referenceDate: DateTime(2026, 7),
      );

      expect(result, 3100);
    });

    test('last day of month does not scale spend', () {
      // 15000 / 30 * 30 = 15000 (exact in double: 15000/30 = 500)
      final result = projectMonthEnd(
        spentSoFar: 15000,
        referenceDate: DateTime(2026, 9, 30),
      );

      expect(result, 15000);
    });

    test('zero spend projects zero', () {
      final result = projectMonthEnd(
        spentSoFar: 0,
        referenceDate: DateTime(2026, 9, 24),
      );

      expect(result, 0);
    });

    test('negative spend projects zero', () {
      final result = projectMonthEnd(
        spentSoFar: -500,
        referenceDate: DateTime(2026, 9, 24),
      );

      expect(result, 0);
    });

    test('uses 28 days for non-leap February', () {
      // 100 / 10 * 28 = 280
      final result = projectMonthEnd(
        spentSoFar: 100,
        referenceDate: DateTime(2025, 2, 10),
      );

      expect(result, 280);
    });

    test('uses 29 days for leap February', () {
      // 100 / 10 * 29 = 290
      final result = projectMonthEnd(
        spentSoFar: 100,
        referenceDate: DateTime(2024, 2, 10),
      );

      expect(result, 290);
    });

    test('scales mid-month spend in a 31-day month', () {
      // 16000 / 16 * 31 = 31000 (exact: 16000/16 = 1000)
      final result = projectMonthEnd(
        spentSoFar: 16000,
        referenceDate: DateTime(2026, 1, 16),
      );

      expect(result, 31000);
    });

    test('matches expected projection within double tolerance', () {
      // Non-exact division: 999 / 7 * 30 (April = 30 days) — tolerance covers
      // IEEE-754 rounding.
      final result = projectMonthEnd(
        spentSoFar: 999,
        referenceDate: DateTime(2026, 4, 7),
      );

      expect(result, closeTo(999 / 7 * 30, 1e-9));
    });
  });
}
