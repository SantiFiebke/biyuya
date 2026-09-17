import 'dart:convert';

import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Syncs categories from Flutter to SharedPreferences
/// so the native Android widget can read them.
///
/// Kotlin reads from FlutterSharedPreferences.xml with key "flutter.widget_categories".
/// Flutter shared_preferences writes with flutter. prefix automatically.
class WidgetCategorySync {
  static const _key = 'widget_categories';

  static Future<void> syncCategories(List<Category> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonArray = categories
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'color': c.color ?? '',
              'icon': c.icon ?? '',
            },
          )
          .toList();
      await prefs.setString(_key, jsonEncode(jsonArray));
    } on Exception catch (e) {
      // Widget shows empty state on failure — no crash needed.
      _log.w('Failed to sync categories to widget', error: e);
    }
  }

  static Future<void> clearCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } on Exception catch (e) {
      _log.w('Failed to clear widget categories', error: e);
    }
  }
}
