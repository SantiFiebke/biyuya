import 'dart:async';

import 'package:biyuya/src/core/data/models/user_profile_model.dart';
import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/domain/entities/household.dart';
import 'package:biyuya/src/features/auth/domain/models/household_model.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/categories/data/default_categories.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthRepositoryImpl implements AuthRepositoryBase {
  const AuthRepositoryImpl(this._client);

  final supabase.SupabaseClient _client;

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
  }) async {
    try {
      // 1. Registro técnico pasando metadata de usuario a Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'first_name': name, 'last_name': lastName},
      );

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
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

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
          .single();

      final profile = UserProfileModel.fromJson(data);
      return Success(profile);
    } on Exception catch (e) {
      return Error(AuthFailure('Error al recuperar el perfil de usuario: $e'));
    }
  }

  @override
  Future<Result<Household, AuthFailure>> createHousehold({
    required String householdName,
  }) async {
    try {
      final data = await _client.rpc<Map<String, dynamic>>(
        'create_household',
        params: <String, dynamic>{
          'p_name': householdName,
          'p_categories': defaultCategories.map((c) => c.toJson()).toList(),
        },
      );
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
      final data = await _client.rpc<Map<String, dynamic>>(
        'join_household',
        params: <String, dynamic>{'p_invite_code': inviteCode},
      );
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
          .order('name');

      final members = data.map(UserProfileModel.fromJson).toList();
      return Success(members);
    } on Exception catch (e) {
      return Error(AuthFailure('Error al obtener miembros del hogar: $e'));
    }
  }

  @override
  Future<Result<void, AuthFailure>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Success(null);
    } on Exception catch (e) {
      return Error(AuthFailure('Error al cerrar sesión: $e'));
    }
  }

  @override
  Future<Result<void, AuthFailure>> leaveHousehold() async {
    try {
      await _client.rpc<void>('leave_household');
      return const Success(null);
    } on Exception catch (e) {
      return Error(AuthFailure('Error al salir del hogar: $e'));
    }
  }

  @override
  Future<Result<void, AuthFailure>> deleteHousehold() async {
    try {
      await _client.rpc<void>('delete_household');
      return const Success(null);
    } on Exception catch (e) {
      return Error(AuthFailure('Error al eliminar el hogar: $e'));
    }
  }
}
