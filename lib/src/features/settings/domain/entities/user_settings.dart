import 'package:equatable/equatable.dart';

class UserSettings extends Equatable {
  const UserSettings({this.debtSettlementEnabled = true});

  final bool debtSettlementEnabled;

  UserSettings copyWith({bool? debtSettlementEnabled}) {
    return UserSettings(
      debtSettlementEnabled:
          debtSettlementEnabled ?? this.debtSettlementEnabled,
    );
  }

  @override
  List<Object?> get props => [debtSettlementEnabled];
}
