import 'package:biyuya/src/core/network/network_timeout.dart';
import 'package:biyuya/src/features/settings/data/models/user_settings_model.dart';
import 'package:biyuya/src/features/settings/domain/entities/user_settings.dart';
import 'package:biyuya/src/features/settings/domain/repositories/settings_repository_base.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SettingsRepositoryImpl implements SettingsRepositoryBase {
  const SettingsRepositoryImpl(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<Result<UserSettings, SettingsFailure>> getSettings() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return Success(UserSettingsModel.defaults());
    }

    try {
      final data = await _client
          .from('user_settings')
          .select()
          .eq('user_id', uid)
          .maybeSingle()
          .timeout(kNetworkTimeout);

      if (data == null) {
        return Success(UserSettingsModel.defaults());
      }
      return Success(UserSettingsModel.fromJson(data));
    } on Exception catch (e) {
      return Error(SettingsFailure('Error al obtener la configuración: $e'));
    }
  }

  @override
  Future<Result<void, SettingsFailure>> saveSettings({
    required bool debtSettlementEnabled,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Error(
        SettingsFailure('No hay sesión activa para guardar la configuración.'),
      );
    }

    try {
      await _client
          .from('user_settings')
          .upsert({
            'user_id': uid,
            'debt_settlement_enabled': debtSettlementEnabled,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id')
          .timeout(kNetworkTimeout);
      return const Success(null);
    } on Exception catch (e) {
      return Error(SettingsFailure('Error al guardar la configuración: $e'));
    }
  }
}
