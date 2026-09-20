import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    required this.lastName,
    this.householdId,
    this.role = 'member',
  });

  final String id;
  final String name;
  final String lastName;
  final String? householdId;
  final String role;

  bool get hasHousehold => householdId != null && householdId!.isNotEmpty;
  bool get isOwner => role == 'owner';

  @override
  List<Object?> get props => [id, name, lastName, householdId, role];
}
