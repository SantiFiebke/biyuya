import 'dart:convert';

import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/domain/models/category_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache for categories backed by [SharedPreferences].
///
/// Plain class (no Riverpod annotation) so it can be injected.
class CategoryCache {
  const CategoryCache();

  static const _key = 'cached_categories';

  Future<void> save(List<Category> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(categories.map(_toCacheJson).toList());
    await prefs.setString(_key, encoded);
  }

  Future<List<Category>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return null;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // Full map including id/created_at, unlike CategoryModel.toJson (insert payload).
  Map<String, dynamic> _toCacheJson(Category category) {
    return {
      'id': category.id,
      'name': category.name,
      'color': category.color,
      'icon': category.icon,
      'household_id': category.householdId,
      'budget_amount': category.budgetAmount,
      'created_at': category.createdAt.toIso8601String(),
    };
  }
}
