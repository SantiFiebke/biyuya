import 'package:biyuya/src/core/presentation/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatHumanDate', () {
    test('today', () {
      expect(formatHumanDate(DateTime.now()), 'Hoy');
    });

    test('yesterday', () {
      final y = DateTime.now().subtract(const Duration(days: 1));
      expect(formatHumanDate(y), 'Ayer');
    });

    test('older date uses day + month name', () {
      expect(formatHumanDate(DateTime(2025, 5, 14)), '14 de mayo');
    });
  });
}
