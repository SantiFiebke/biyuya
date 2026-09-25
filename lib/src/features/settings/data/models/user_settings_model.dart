import 'package:biyuya/src/features/settings/domain/entities/user_settings.dart';

class UserSettingsModel extends UserSettings {
  const UserSettingsModel({
    super.debtSettlementEnabled,
    super.monthProjectionEnabled,
    super.debtSettlementExplainerSeen,
    super.monthProjectionExplainerSeen,
    super.firstStepsDismissed,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      debtSettlementEnabled: json['debt_settlement_enabled'] as bool? ?? false,
      monthProjectionEnabled:
          json['month_projection_enabled'] as bool? ?? false,
      debtSettlementExplainerSeen:
          json['debt_settlement_explainer_seen'] as bool? ?? false,
      monthProjectionExplainerSeen:
          json['month_projection_explainer_seen'] as bool? ?? false,
      firstStepsDismissed: json['first_steps_dismissed'] as bool? ?? false,
    );
  }

  /// Filas ausentes: flags de features nuevos, todos apagados por defecto.
  factory UserSettingsModel.defaults() => const UserSettingsModel();

  Map<String, dynamic> toJson() {
    return {
      'debt_settlement_enabled': debtSettlementEnabled,
      'month_projection_enabled': monthProjectionEnabled,
      'debt_settlement_explainer_seen': debtSettlementExplainerSeen,
      'month_projection_explainer_seen': monthProjectionExplainerSeen,
      'first_steps_dismissed': firstStepsDismissed,
    };
  }

  @override
  UserSettingsModel copyWith({
    bool? debtSettlementEnabled,
    bool? monthProjectionEnabled,
    bool? debtSettlementExplainerSeen,
    bool? monthProjectionExplainerSeen,
    bool? firstStepsDismissed,
  }) {
    return UserSettingsModel(
      debtSettlementEnabled:
          debtSettlementEnabled ?? this.debtSettlementEnabled,
      monthProjectionEnabled:
          monthProjectionEnabled ?? this.monthProjectionEnabled,
      debtSettlementExplainerSeen:
          debtSettlementExplainerSeen ?? this.debtSettlementExplainerSeen,
      monthProjectionExplainerSeen:
          monthProjectionExplainerSeen ?? this.monthProjectionExplainerSeen,
      firstStepsDismissed: firstStepsDismissed ?? this.firstStepsDismissed,
    );
  }
}
