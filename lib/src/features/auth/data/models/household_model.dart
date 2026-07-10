import 'package:biyuya/src/features/auth/domain/entities/household.dart';

class HouseholdModel extends Household {
  const HouseholdModel({
    required super.id,
    required super.name,
    required super.createdAt,
  });

  factory HouseholdModel.fromJson(Map<String, dynamic> json) {
    return HouseholdModel(
      id: json['id'] as String,
      name: json['nombre'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
    };
  }
}
