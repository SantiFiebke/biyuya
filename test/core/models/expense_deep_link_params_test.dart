import 'package:biyuya/src/core/models/expense_deep_link_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseDeepLinkParams.fromUri', () {
    test('parses amount correctly from query params', () {
      final uri = Uri.parse(
        'biyuya://expense/new?amount=1250.50&category_id=3',
      );
      final params = ExpenseDeepLinkParams.fromUri(uri);

      expect(params.amount, 1250.50);
    });

    test('parses category_id correctly from query params', () {
      final uri = Uri.parse('biyuya://expense/new?amount=100&category_id=5');
      final params = ExpenseDeepLinkParams.fromUri(uri);

      expect(params.categoryId, 5);
    });

    test('handles missing amount', () {
      final uri = Uri.parse('biyuya://expense/new?category_id=3');
      final params = ExpenseDeepLinkParams.fromUri(uri);

      expect(params.amount, isNull);
    });

    test('handles missing category_id', () {
      final uri = Uri.parse('biyuya://expense/new?amount=100');
      final params = ExpenseDeepLinkParams.fromUri(uri);

      expect(params.categoryId, isNull);
    });

    test('handles invalid number strings', () {
      final uri = Uri.parse('biyuya://expense/new?amount=abc&category_id=xyz');
      final params = ExpenseDeepLinkParams.fromUri(uri);

      expect(params.amount, isNull);
      expect(params.categoryId, isNull);
    });

    test('handles empty query string', () {
      final uri = Uri.parse('biyuya://expense/new');
      final params = ExpenseDeepLinkParams.fromUri(uri);

      expect(params.amount, isNull);
      expect(params.categoryId, isNull);
    });
  });

  group('hasData', () {
    test('returns true when amount is provided', () {
      const params = ExpenseDeepLinkParams(amount: 100);
      expect(params.hasData, isTrue);
    });

    test('returns true when categoryId is provided', () {
      const params = ExpenseDeepLinkParams(categoryId: 3);
      expect(params.hasData, isTrue);
    });

    test('returns true when both are provided', () {
      const params = ExpenseDeepLinkParams(amount: 100, categoryId: 3);
      expect(params.hasData, isTrue);
    });

    test('returns false when both are null', () {
      const params = ExpenseDeepLinkParams();
      expect(params.hasData, isFalse);
    });
  });

  group('autoSubmit', () {
    test('defaults to true', () {
      const params = ExpenseDeepLinkParams();
      expect(params.autoSubmit, isTrue);
    });

    test('can be set to false', () {
      const params = ExpenseDeepLinkParams(autoSubmit: false);
      expect(params.autoSubmit, isFalse);
    });
  });
}
