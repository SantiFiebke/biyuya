import 'package:biyuya/src/core/data/widget_daily_total_sync.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('biyuya/widget');
  final log = <MethodCall>[];

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

  group('missing platform handler', () {
    test('syncTotal persists keys even when channel throws MissingPluginException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);

      // No handler → MissingPluginException. Should not throw.
      await WidgetDailyTotalSync.syncTotal(99.99);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('widget_daily_total'), '99.99');

      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(prefs.getString('widget_daily_date'), today);
    });

    test('clearTotal removes keys even when channel throws MissingPluginException', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_daily_total', '50');
      await prefs.setString('widget_daily_date', '2026-06-01');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);

      await WidgetDailyTotalSync.clearTotal();

      expect(prefs.getString('widget_daily_total'), isNull);
      expect(prefs.getString('widget_daily_date'), isNull);
    });
  });
}
