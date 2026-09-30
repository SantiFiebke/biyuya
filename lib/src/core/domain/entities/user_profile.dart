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

  /// [householdId] como entero, o `null` si no hay hogar o el id es inválido.
  int? get householdIdValue => hasHousehold ? int.tryParse(householdId!) : null;

  bool get isOwner => role == 'owner';

  @override
  List<Object?> get props => [id, name, lastName, householdId, role];
}
