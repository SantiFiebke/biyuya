import 'package:biyuya/src/core/data/models/user_profile_model.dart';
import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/data/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/auth/domain/entities/household.dart';
import 'package:biyuya/src/features/auth/domain/models/household_model.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthRepositoryImpl implements AuthRepositoryBase {
  const AuthRepositoryImpl(this._client);

  final supabase.SupabaseClient _client;

  @override
  Stream<UserProfile?> get onAuthStateChanged {
    // List supabase auth state changes and map them to UserProfile
    return _client.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user == null) {
        return null;
      }

      // If user is not null, fetch the corresponding UserProfile from
      // the database
      final result = await getUserProfile(user.id);
      return result.when(
        (profile) => profile,
        (error) => null,
      );
    });
  }

  @override
  Future<Result<UserProfile, AuthFailure>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String lastName,
  }) async {
    try {
      // 1. Technical registration with Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return const Error(AuthFailure('No se pudo crear el usuario.'));
      }

      // 2. Immediate creation of their profile mirror
      //  (with household_id initially null)
      final profileModel = UserProfileModel(
        id: user.id,
        name: name,
        lastName: lastName,
      );

      await _client.from('profiles').insert(profileModel.toJson());

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

      // Buscamos su perfil de base de datos
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
      // 1. Create a new household in the database
      final householdData = await _client
          .from('households')
          .insert({'name': householdName})
          .select()
          .single();

      final household = HouseholdModel.fromJson(householdData);

      // 2. Immediately link the user to the newly created household
      final joinResult = await joinHousehold(
        householdId: household.id,
        userId: userId,
      );

      return joinResult.when(
        (success) => Success(household),
        Error.new,
      );
    } on Exception catch (e) {
      return Error(AuthFailure('Error al crear el hogar: $e'));
    }
  }

  @override
  Future<Result<UserProfile, AuthFailure>> joinHousehold({
    required String householdId,
    required String userId,
  }) async {
    try {
      // Update the user's profile to link them to the specified household.
      // Triggering the RLS (Row Level Security) policies in Supabase to ensure
      // that the user can only join households they are allowed to.
      final updatedData = await _client
          .from('profiles')
          .update({'household_id': householdId})
          .eq('id', userId)
          .select()
          .single();

      return Success(UserProfileModel.fromJson(updatedData));
    } on Exception catch (e) {
      return Error(
        AuthFailure(
          'Error al unirse al hogar. Verifica el código ingresado: $e',
        ),
      );
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
