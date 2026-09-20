import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/domain/entities/household.dart';
import 'package:equatable/equatable.dart';
import 'package:multiple_result/multiple_result.dart';

class AuthFailure extends Equatable {
  const AuthFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

abstract class AuthRepositoryBase {
  Stream<UserProfile?> get onAuthStateChanged;

  /// Escucha cambios en el perfil del usuario (ej: household_id modificado)
  Stream<UserProfile?> onProfileChanged({required String userId});

  /// Registro técnico con Email y Password
  Future<Result<UserProfile, AuthFailure>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String lastName,
  });

  /// Login tradicional
  Future<Result<UserProfile, AuthFailure>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Cierre de sesión y limpieza local
  Future<Result<void, AuthFailure>> signOut();

  /// Obtiene el perfil de un usuario por su ID único de Auth
  Future<Result<UserProfile, AuthFailure>> getUserProfile(String userId);

  /// Fase Onboarding: Crea un nuevo hogar e inmediatamente vincula al usuario
  Future<Result<Household, AuthFailure>> createHousehold({
    required String householdName,
  });

  /// Fase Onboarding: Vincula a un usuario a un hogar existente mediante código de invitación
  Future<Result<UserProfile, AuthFailure>> joinHousehold({
    required String inviteCode,
  });

  /// Obtiene los miembros de un hogar por su ID
  Future<Result<List<UserProfile>, AuthFailure>> getHouseholdMembers({
    required int householdId,
  });

  /// Sale del hogar actual
  Future<Result<void, AuthFailure>> leaveHousehold();

  /// Elimina el hogar actual (solo admin)
  Future<Result<void, AuthFailure>> deleteHousehold();
}
