import 'package:biyuya/src/core/domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    required super.lastName,
    super.householdId,
    super.role,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      lastName: json['last_name'] as String,
      householdId: json['household_id']?.toString(),
      role: json['role'] as String? ?? 'member',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'last_name': lastName,
      'household_id': householdId,
      'role': role,
    };
  }

  UserProfileModel copyWith({
    String? id,
    String? name,
    String? lastName,
    String? householdId,
    String? role,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      householdId: householdId ?? this.householdId,
      role: role ?? this.role,
    );
  }
}
