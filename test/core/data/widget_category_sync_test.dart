import 'dart:convert';

import 'package:biyuya/src/core/data/widget_category_sync.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WidgetCategorySync.syncCategories', () {
    test('writes correct JSON format to SharedPreferences', () async {
      final categories = [
        Category(
          id: 1,
          name: 'Food',
          householdId: 1,
          createdAt: DateTime(2025),
          color: '#4CAF50',
          icon: '63046',
        ),
        Category(
          id: 2,
          name: 'Transport',
          householdId: 1,
          createdAt: DateTime(2025),
          color: '#2196F3',
          icon: '57681',
        ),
      ];

      await WidgetCategorySync.syncCategories(categories);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('widget_categories');
      expect(raw, isNotNull);

      final decoded = jsonDecode(raw!) as List;
      expect(decoded, hasLength(2));

      expect(decoded[0]['id'], 1);
      expect(decoded[0]['name'], 'Food');
      expect(decoded[0]['color'], '#4CAF50');
      expect(decoded[0]['icon'], '63046');

      expect(decoded[1]['id'], 2);
      expect(decoded[1]['name'], 'Transport');
    });

    test('handles empty list', () async {
      await WidgetCategorySync.syncCategories([]);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('widget_categories');
      expect(raw, isNotNull);

      final decoded = jsonDecode(raw!) as List;
      expect(decoded, isEmpty);
    });

    test('handles categories with null color/icon', () async {
      final categories = [
        Category(
          id: 1,
          name: 'Misc',
          householdId: 1,
          createdAt: DateTime(2025),
        ),
      ];

      await WidgetCategorySync.syncCategories(categories);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('widget_categories');
      final decoded = jsonDecode(raw!) as List;

      expect(decoded[0]['color'], '');
      expect(decoded[0]['icon'], '');
    });
  });

  group('WidgetCategorySync.clearCategories', () {
    test('removes the key from SharedPreferences', () async {
      // Pre-populate
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_categories', '[{"id":1}]');

      await WidgetCategorySync.clearCategories();

      final result = prefs.getString('widget_categories');
      expect(result, isNull);
    });
  });
}
