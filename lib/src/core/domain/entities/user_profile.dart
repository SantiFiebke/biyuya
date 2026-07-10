import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    required this.lastName,
    this.householdId,
  });

  final String id;
  final String name;
  final String lastName;
  final String? householdId;

  bool get hasHousehold => householdId != null && householdId!.isNotEmpty;

  @override
  List<Object?> get props => [id, name, lastName, householdId];
}
