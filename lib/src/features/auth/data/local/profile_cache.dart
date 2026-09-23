import 'dart:convert';

import 'package:biyuya/src/core/data/models/user_profile_model.dart';
import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache for the current user profile backed by [SharedPreferences].
///
/// Plain class (no Riverpod annotation) so it can be injected.
class ProfileCache {
  const ProfileCache();

  static const _key = 'cached_profile';

  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final model = UserProfileModel(
      id: profile.id,
      name: profile.name,
      lastName: profile.lastName,
      householdId: profile.householdId,
      role: profile.role,
    );
    await prefs.setString(_key, jsonEncode(model.toJson()));
  }

  Future<UserProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return null;
    }

    return UserProfileModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
