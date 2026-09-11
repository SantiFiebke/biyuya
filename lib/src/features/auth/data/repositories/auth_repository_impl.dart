import 'dart:async';

import 'package:biyuya/src/core/data/models/user_profile_model.dart';
import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/domain/entities/household.dart';
import 'package:biyuya/src/features/auth/domain/models/household_model.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
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
    required String userId,
  }) async {
    try {
      final householdData = await _client
          .from('households')
          .insert({'name': householdName})
          .select()
          .single();

      final household = HouseholdModel.fromJson(householdData);

      // Link user to household directly by ID (just created)
      await _client
          .from('profiles')
          .update({'household_id': household.id})
          .eq('id', userId);

      return Success(household);
    } on Exception catch (e) {
      return Error(AuthFailure('Error al crear el hogar: $e'));
    }
  }

  @override
  Future<Result<UserProfile, AuthFailure>> joinHousehold({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      final householdData = await _client
          .from('households')
          .select('id')
          .eq('invite_code', inviteCode.toUpperCase())
          .maybeSingle();

      if (householdData == null) {
        return const Error(AuthFailure('Código de invitación no válido.'));
      }

      final householdId = (householdData['id'] as num).toString();

      final updatedData = await _client
          .from('profiles')
          .update({'household_id': householdId})
          .eq('id', userId)
          .select()
          .single();

      return Success(UserProfileModel.fromJson(updatedData));
    } on Exception catch (e) {
      return Error(AuthFailure('Error al unirse al hogar: $e'));
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
}
