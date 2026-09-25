import 'package:biyuya/src/features/settings/domain/entities/user_settings.dart';

class UserSettingsModel extends UserSettings {
  const UserSettingsModel({super.debtSettlementEnabled});

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      debtSettlementEnabled: json['debt_settlement_enabled'] as bool? ?? true,
    );
  }

  /// Fila ausente: deuda pendiente de liquidación activada por defecto.
  factory UserSettingsModel.defaults() => const UserSettingsModel();

  Map<String, dynamic> toJson() {
    return {'debt_settlement_enabled': debtSettlementEnabled};
  }

  @override
  UserSettingsModel copyWith({bool? debtSettlementEnabled}) {
    return UserSettingsModel(
      debtSettlementEnabled:
          debtSettlementEnabled ?? this.debtSettlementEnabled,
    );
  }
}
