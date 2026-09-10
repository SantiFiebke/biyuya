import 'package:biyuya/src/features/categories/domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.householdId,
    required super.createdAt,
    super.color,
    super.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      householdId: (json['household_id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'icon': icon,
      'household_id': householdId,
    };
  }
}
