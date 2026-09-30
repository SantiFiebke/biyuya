import 'dart:async';

import 'package:biyuya/src/core/data/models/user_profile_model.dart';
import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/core/network/network_timeout.dart';
import 'package:biyuya/src/features/auth/data/local/profile_cache.dart';
import 'package:biyuya/src/features/auth/domain/entities/household.dart';
import 'package:biyuya/src/features/auth/domain/models/household_model.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/categories/data/default_categories.dart';
import 'package:biyuya/src/features/categories/data/local/category_cache.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthRepositoryImpl implements AuthRepositoryBase {
  const AuthRepositoryImpl(
    this._client,
    this._profileCache,
    this._categoryCache,
  );

  final supabase.SupabaseClient _client;
  final ProfileCache _profileCache;
  final CategoryCache _categoryCache;

  @override
  Stream<UserProfile?> get onAuthStateChanged {
    return _client.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user == null) {
        return null;
      }

      final result = await getUserProfile(user.id);
      return await result.when((profile) => profile, (error) => null);
    });
  }

  @override
  Stream<UserProfile?> onProfileChanged({required String userId}) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .asyncMap(
          (_) =>
              getUserProfile(userId).then((r) => r.when((p) => p, (_) => null)),
        );
  }

  @override
  Future<Result<UserProfile, AuthFailure>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String lastName,
    required bool acceptedTerms,
  }) async {
    try {
      // 1. Registro técnico pasando metadata de usuario a Supabase Auth
      final response = await _client.auth
          .signUp(
            email: email,
            password: password,
            data: {
              'first_name': name,
              'last_name': lastName,
              'accepted_terms': acceptedTerms,
              'accepted_at': DateTime.now().toUtc().toIso8601String(),
              'terms_version': '1.0',
            },
          )
          .timeout(kNetworkTimeout);

      final user = response.user;
      if (user == null) {
        return const Error(AuthFailure('No se pudo crear el usuario.'));
      }

      final profileModel = UserProfileModel(
        id: user.id,
        name: name,
        lastName: lastName,
      );

      return Success(profileModel);
    } on supabase.AuthException catch (e) {
      return Error(AuthFailure(e.message));
    } on Exception catch (e) {
      return Error(AuthFailure('Error inesperado durante el registro: $e'));
    }
  }

  @override
  Future<Result<UserProfile, AuthFailure>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(kNetworkTimeout);

      final user = response.user;
      if (user == null) {
        return const Error(AuthFailure('Usuario no encontrado.'));
      }

      return await getUserProfile(user.id);
    } on supabase.AuthException catch (e) {
      return Error(AuthFailure(e.message));
    } on Exception catch (e) {
      return Error(AuthFailure('Error de conexión: $e'));
    }
  }

  @override
  Future<Result<UserProfile, AuthFailure>> getUserProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single()
          .timeout(kNetworkTimeout);

      final profile = UserProfileModel.fromJson(data);
      await _profileCache.save(profile);
      return Success(profile);
    } on Exception catch (e) {
      final cached = await _profileCache.load();
      if (cached != null && cached.id == userId) {
        return Success(cached);
      }
      return Error(AuthFailure('Error al recuperar el perfil de usuario: $e'));
    }
  }

  @override
  Future<Result<Household, AuthFailure>> createHousehold({
    required String householdName,
  }) async {
    try {
      final data = await _client
          .rpc<Map<String, dynamic>>(
            'create_household',
            params: <String, dynamic>{
              'p_name': householdName,
              'p_categories': defaultCategories.map((c) => c.toJson()).toList(),
            },
          )
          .timeout(kNetworkTimeout);
      return Success(HouseholdModel.fromJson(data));
    } on Exception catch (e) {
      return Error(AuthFailure('Error al crear el hogar: $e'));
    }
  }

  @override
  Future<Result<UserProfile, AuthFailure>> joinHousehold({
    required String inviteCode,
  }) async {
    try {
      final data = await _client
          .rpc<Map<String, dynamic>>(
            'join_household',
            params: <String, dynamic>{'p_invite_code': inviteCode},
          )
          .timeout(kNetworkTimeout);
      return Success(UserProfileModel.fromJson(data));
    } on Exception catch (e) {
      return Error(AuthFailure('Error al unirse al hogar: $e'));
    }
  }

  @override
  Future<Result<List<UserProfile>, AuthFailure>> getHouseholdMembers({
    required int householdId,
  }) async {
    try {
      final data = await _client
          .from('profiles')
          .select('id, name, last_name, household_id')
          .eq('household_id', householdId)
          .order('name')
          .timeout(kNetworkTimeout);

      final members = data.map(UserProfileModel.fromJson).toList();
      return Success(members);
    } on Exception catch (e) {
      return Error(AuthFailure('Error al obtener miembros del hogar: $e'));
    }
  }

  @override
  Future<Result<void, AuthFailure>> signOut() async {
    try {
      await _client.auth.signOut().timeout(kNetworkTimeout);
      // Clear user-scoped caches so the next user doesn't inherit them.
      await _profileCache.clear();
      await _categoryCache.clear();
      return const Success(null);
    } on Exception catch (e) {
      return Error(AuthFailure('Error al cerrar sesión: $e'));
    }
  }

  @override
  Future<Result<void, AuthFailure>> leaveHousehold() async {
    try {
      await _client.rpc<void>('leave_household').timeout(kNetworkTimeout);
      await _profileCache.clear();
      await _categoryCache.clear();
      return const Success(null);
    } on Exception catch (e) {
      return Error(AuthFailure('Error al salir del hogar: $e'));
    }
  }

  @override
  Future<Result<void, AuthFailure>> deleteHousehold() async {
    try {
      await _client.rpc<void>('delete_household').timeout(kNetworkTimeout);
      await _profileCache.clear();
      await _categoryCache.clear();
      return const Success(null);
    } on Exception catch (e) {
      return Error(AuthFailure('Error al eliminar el hogar: $e'));
    }
  }

  @override
  Future<Result<void, AuthFailure>> deleteAccount() async {
    try {
      await _client.functions.invoke('delete-account').timeout(kNetworkTimeout);
    } on Exception catch (e) {
      return Error(AuthFailure('No se pudo eliminar la cuenta: $e'));
    }

    // La cuenta ya no existe en Auth: cerrar sesión local (sin llamada de
    // red, el refresh token fue revocado) y limpiar cachés como en signOut.
    try {
      await _client.auth.signOut();
    } on Exception catch (_) {
      // ignorado: el usuario ya fue eliminado
    }
    await _profileCache.clear();
    await _categoryCache.clear();
    return const Success(null);
  }
}
