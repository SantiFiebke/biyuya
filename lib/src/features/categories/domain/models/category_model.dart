import 'package:biyuya/src/features/categories/domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.householdId,
    required super.createdAt,
    super.color,
    super.icon,
    super.budgetAmount,
    super.isExpense,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      householdId: (json['household_id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      budgetAmount: (json['budget_amount'] as num?)?.toDouble(),
      isExpense: (json['is_expense'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'icon': icon,
      'household_id': householdId,
      'budget_amount': budgetAmount,
      'is_expense': isExpense,
    };
  }
}
