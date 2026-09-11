import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryBreakdown', () {
    test('creates correctly with all fields', () {
      const breakdown = CategoryBreakdown(
        categoryId: 1,
        categoryName: 'Food',
        amount: 500,
        percentage: 50,
        categoryColor: '#FF0000',
        categoryIcon: '12345',
      );

      expect(breakdown.categoryId, 1);
      expect(breakdown.categoryName, 'Food');
      expect(breakdown.amount, 500);
      expect(breakdown.percentage, 50.0);
      expect(breakdown.categoryColor, '#FF0000');
      expect(breakdown.categoryIcon, '12345');
    });

    test('handles null color and icon', () {
      const breakdown = CategoryBreakdown(
        categoryId: 2,
        categoryName: 'Transport',
        amount: 200,
        percentage: 20,
      );

      expect(breakdown.categoryColor, isNull);
      expect(breakdown.categoryIcon, isNull);
    });

    test('supports equality via Equatable', () {
      const a = CategoryBreakdown(
        categoryId: 1,
        categoryName: 'Food',
        amount: 500,
        percentage: 50,
      );

      const b = CategoryBreakdown(
        categoryId: 1,
        categoryName: 'Food',
        amount: 500,
        percentage: 50,
      );

      expect(a, equals(b));
    });
  });
}
