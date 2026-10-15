import 'package:biyuya/src/features/reports/domain/entities/savings_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavingsReport', () {
    test('creates correctly with all fields', () {
      final entries = [
        SavingsEntry(
          date: DateTime(2026, 9, 5),
          amount: 100,
          description: 'Ahorro',
          source: 'Ahorro',
        ),
      ];

      final report = SavingsReport(
        year: 2026,
        month: 9,
        totalSaved: 100,
        goalAmount: 600,
        progressPct: 100 / 600 * 100,
        entries: entries,
      );

      expect(report.year, 2026);
      expect(report.month, 9);
      expect(report.totalSaved, 100);
      expect(report.goalAmount, 600);
      expect(report.progressPct, closeTo(16.6667, 0.001));
      expect(report.entries, hasLength(1));
    });

    test('supports equality via Equatable', () {
      const a = SavingsReport(
        year: 2026,
        month: 9,
        totalSaved: 100,
        goalAmount: 600,
        progressPct: 16.6667,
        entries: [],
      );
      const b = SavingsReport(
        year: 2026,
        month: 9,
        totalSaved: 100,
        goalAmount: 600,
        progressPct: 16.6667,
        entries: [],
      );

      expect(a, equals(b));
    });
  });

  group('SavingsEntry', () {
    test('creates correctly with optional fields', () {
      final entry = SavingsEntry(
        date: DateTime(2026, 9, 5),
        amount: 250.5,
        description: 'Sueldo',
        source: 'Ingreso',
      );

      expect(entry.date, DateTime(2026, 9, 5));
      expect(entry.amount, 250.5);
      expect(entry.description, 'Sueldo');
      expect(entry.source, 'Ingreso');
    });

    test('handles null description and source', () {
      final entry = SavingsEntry(date: DateTime(2026, 9, 5), amount: 10);

      expect(entry.description, isNull);
      expect(entry.source, isNull);
    });
  });
}
