import 'package:equatable/equatable.dart';

class UserSettings extends Equatable {
  const UserSettings({
    this.debtSettlementEnabled = false,
    this.monthProjectionEnabled = false,
    this.debtSettlementExplainerSeen = false,
    this.monthProjectionExplainerSeen = false,
    this.firstStepsDismissed = false,
  });

  final bool debtSettlementEnabled;
  final bool monthProjectionEnabled;
  final bool debtSettlementExplainerSeen;
  final bool monthProjectionExplainerSeen;
  final bool firstStepsDismissed;

  UserSettings copyWith({
    bool? debtSettlementEnabled,
    bool? monthProjectionEnabled,
    bool? debtSettlementExplainerSeen,
    bool? monthProjectionExplainerSeen,
    bool? firstStepsDismissed,
  }) {
    return UserSettings(
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

  @override
  List<Object?> get props => [
    debtSettlementEnabled,
    monthProjectionEnabled,
    debtSettlementExplainerSeen,
    monthProjectionExplainerSeen,
    firstStepsDismissed,
  ];
}
