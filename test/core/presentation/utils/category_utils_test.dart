import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCategoryColor', () {
    test('returns correct Color for valid hex with #', () {
      final result = parseCategoryColor('#FF0000');
      expect(result, isNotNull);
      expect(result, const Color(0xFFFF0000));
    });

    test('returns correct Color for valid hex without #', () {
      final result = parseCategoryColor('00FF00');
      expect(result, isNotNull);
      expect(result, const Color(0xFF00FF00));
    });

    test('returns null for invalid hex characters', () {
      expect(parseCategoryColor('XYZ'), isNull);
    });

    test('returns null for null input', () {
      expect(parseCategoryColor(null), isNull);
    });

    test('returns null for empty string', () {
      expect(parseCategoryColor(''), isNull);
    });
  });

  group('iconFromCodePoint', () {
    test('returns correct IconData for valid codepoint string', () {
      final result = iconFromCodePoint('63046');
      expect(result.codePoint, 63046);
      expect(result.fontFamily, 'MaterialIcons');
    });

    test('returns Icons.category for null input', () {
      final result = iconFromCodePoint(null);
      expect(result, Icons.category);
    });

    test('returns Icons.category for empty string', () {
      final result = iconFromCodePoint('');
      expect(result, Icons.category);
    });

    test('returns Icons.category for non-numeric string', () {
      final result = iconFromCodePoint('abc');
      expect(result, Icons.category);
    });
  });
}
