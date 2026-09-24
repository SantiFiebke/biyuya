import 'dart:convert';

import 'package:biyuya/src/core/data/widget_daily_total_sync.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('biyuya/widget');
  final log = <MethodCall>[];

  Category category({
    required int id,
    String? name,
    String? color,
    String? icon,
  }) {
    return Category(
      id: id,
      name: name ?? 'Category $id',
      householdId: 1,
      createdAt: DateTime(2026),
      color: color,
      icon: icon,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          log.add(methodCall);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('syncTotal', () {
    test('persists total as String "123.45" and date as yyyy-MM-dd', () async {
      await WidgetDailyTotalSync.syncTotal(123.45);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('widget_daily_total'), '123.45');

      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(prefs.getString('widget_daily_date'), today);
    });

    test('persists zero total as "0.0"', () async {
      await WidgetDailyTotalSync.syncTotal(0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('widget_daily_total'), '0.0');
    });

    test('invokes "refresh" on biyuya/widget exactly once', () async {
      await WidgetDailyTotalSync.syncTotal(42);

      expect(log, hasLength(1));
      expect(log.first.method, 'refresh');
    });
  });

  group('clearTotal', () {
    test('removes both keys from SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_daily_total', '100.0');
      await prefs.setString('widget_daily_date', '2026-01-01');

      await WidgetDailyTotalSync.clearTotal();

      expect(prefs.getString('widget_daily_total'), isNull);
      expect(prefs.getString('widget_daily_date'), isNull);
    });

    test('invokes "refresh" on biyuya/widget exactly once', () async {
      await WidgetDailyTotalSync.clearTotal();

      expect(log, hasLength(1));
      expect(log.first.method, 'refresh');
    });

    test('does not throw when keys do not exist', () async {
      expect(WidgetDailyTotalSync.clearTotal(), completes);
    });
  });

  group('syncFeaturedCategories', () {
    test('persists id/name/color JSON capped at 4 categories', () async {
      await WidgetDailyTotalSync.syncFeaturedCategories([
        category(id: 1, name: 'Food', color: '#FF0000'),
        category(id: 2, name: 'Transport', color: '#00FF00'),
        category(id: 3, name: 'Home', color: '#0000FF'),
        category(id: 4, name: 'Fun', color: '#FFFF00'),
        category(id: 5, name: 'Extra', color: '#123456'),
      ]);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('widget_featured_categories');
      expect(raw, isNotNull);

      final decoded = jsonDecode(raw!) as List<dynamic>;
      expect(decoded, hasLength(4));
      expect(decoded[0], {
        'id': 1,
        'name': 'Food',
        'color': '#FF0000',
        'icon': 0,
      });
      expect(decoded[3], {
        'id': 4,
        'name': 'Fun',
        'color': '#FFFF00',
        'icon': 0,
      });
    });

    test('null color falls back to #607D8B', () async {
      await WidgetDailyTotalSync.syncFeaturedCategories([
        category(id: 1, name: 'NoColor'),
      ]);

      final prefs = await SharedPreferences.getInstance();
      final decoded =
          jsonDecode(prefs.getString('widget_featured_categories')!)
              as List<dynamic>;
      expect(decoded, [
        {'id': 1, 'name': 'NoColor', 'color': '#607D8B', 'icon': 0},
      ]);
    });

    test('parses icon string to numeric icon', () async {
      await WidgetDailyTotalSync.syncFeaturedCategories([
        category(id: 1, name: 'Food', icon: '58732'),
      ]);

      final prefs = await SharedPreferences.getInstance();
      final decoded =
          jsonDecode(prefs.getString('widget_featured_categories')!)
              as List<dynamic>;
      expect(decoded, [
        {'id': 1, 'name': 'Food', 'color': '#607D8B', 'icon': 58732},
      ]);
      expect((decoded[0] as Map<String, dynamic>)['icon'], isA<int>());
    });

    test('null icon falls back to numeric 0', () async {
      await WidgetDailyTotalSync.syncFeaturedCategories([
        category(id: 1, name: 'NoIcon'),
      ]);

      final prefs = await SharedPreferences.getInstance();
      final decoded =
          jsonDecode(prefs.getString('widget_featured_categories')!)
              as List<dynamic>;
      expect((decoded[0] as Map<String, dynamic>)['icon'], 0);
    });

    test('invalid (non-numeric) icon falls back to 0', () async {
      await WidgetDailyTotalSync.syncFeaturedCategories([
        category(id: 1, name: 'BadIcon', icon: 'not-a-number'),
      ]);

      final prefs = await SharedPreferences.getInstance();
      final decoded =
          jsonDecode(prefs.getString('widget_featured_categories')!)
              as List<dynamic>;
      expect((decoded[0] as Map<String, dynamic>)['icon'], 0);
    });

    test('empty list persists "[]"', () async {
      await WidgetDailyTotalSync.syncFeaturedCategories([]);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('widget_featured_categories'), '[]');
    });

    test('invokes "refresh" on biyuya/widget exactly once', () async {
      await WidgetDailyTotalSync.syncFeaturedCategories([category(id: 1)]);

      expect(log, hasLength(1));
      expect(log.first.method, 'refresh');
    });
  });

  group('missing platform handler', () {
    test(
      'syncTotal persists keys even when channel throws MissingPluginException',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);

        // No handler → MissingPluginException. Should not throw.
        await WidgetDailyTotalSync.syncTotal(99.99);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('widget_daily_total'), '99.99');

        final today = DateTime.now().toIso8601String().substring(0, 10);
        expect(prefs.getString('widget_daily_date'), today);
      },
    );

    test(
      'clearTotal removes keys even when channel throws MissingPluginException',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('widget_daily_total', '50');
        await prefs.setString('widget_daily_date', '2026-06-01');

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);

        await WidgetDailyTotalSync.clearTotal();

        expect(prefs.getString('widget_daily_total'), isNull);
        expect(prefs.getString('widget_daily_date'), isNull);
      },
    );
  });
}
