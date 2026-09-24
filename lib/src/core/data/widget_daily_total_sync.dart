import 'dart:convert';

import 'package:biyuya/src/core/constants/app_constants.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Syncs today's expense total to SharedPreferences so the native
/// Android widget can display "Gastado hoy: $X.XXX".
class WidgetDailyTotalSync {
  static const _keyTotal = 'widget_daily_total';
  static const _keyDate = 'widget_daily_date';
  static const _keyFeatured = 'widget_featured_categories';
  static const _channel = MethodChannel('biyuya/widget');

  /// Fallback color used when a category has no color assigned.
  static const _fallbackColor = '#607D8B';

  /// Write today's total to SharedPreferences.
  static Future<void> syncTotal(double total) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      // Native reads via getFloat which fails on FlutterSharedPreferences's
      // long-backed double; store as String so Kotlin can do toDoubleOrNull().
      await prefs.setString(_keyTotal, total.toString());
      await prefs.setString(_keyDate, today);
      await _refreshWidget();
    } on Exception catch (e) {
      _log.w('Failed to sync daily total to widget', error: e);
    }
  }

  /// Clear daily total (e.g., on logout).
  static Future<void> clearTotal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyTotal);
      await prefs.remove(_keyDate);
      await _refreshWidget();
    } on Exception catch (e) {
      _log.w('Failed to clear widget daily total', error: e);
    }
  }

  /// Write up to 4 featured categories (id/name/color/icon) as a JSON string so the
  /// native Android widget can render category shortcuts.
  ///
  /// Always writes a value: callers must pass the fallback list when there is
  /// not enough activity, so the native side never reads null.
  static Future<void> syncFeaturedCategories(List<Category> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final featured = categories
          .take(kFeaturedCategoryCount)
          .map(
            (category) => {
              'id': category.id,
              'name': category.name,
              'color': category.color ?? _fallbackColor,
              'icon': int.tryParse(category.icon ?? '') ?? 0,
            },
          )
          .toList();
      await prefs.setString(_keyFeatured, jsonEncode(featured));
      await _refreshWidget();
    } on Exception catch (e) {
      _log.w('Failed to sync featured categories to widget', error: e);
    }
  }

  static Future<void> _refreshWidget() async {
    try {
      await _channel.invokeMethod<void>('refresh');
    } on Exception catch (e) {
      _log.d('Widget refresh skipped: $e');
    }
  }
}
