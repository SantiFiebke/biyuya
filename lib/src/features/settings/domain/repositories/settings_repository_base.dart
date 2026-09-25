import 'package:biyuya/src/features/settings/domain/entities/user_settings.dart';
import 'package:equatable/equatable.dart';
import 'package:multiple_result/multiple_result.dart';

class SettingsFailure extends Equatable {
  const SettingsFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

abstract class SettingsRepositoryBase {
  /// Obtiene la configuración del usuario actual.
  Future<Result<UserSettings, SettingsFailure>> getSettings();

  /// Persiste la configuración del usuario actual.
  Future<Result<void, SettingsFailure>> saveSettings({
    required UserSettings settings,
  });
}
