import 'package:equatable/equatable.dart';

class HouseholdData extends Equatable {
  const HouseholdData({required this.name, this.inviteCode});

  final String name;
  final String? inviteCode;

  @override
  List<Object?> get props => [name, inviteCode];
}
