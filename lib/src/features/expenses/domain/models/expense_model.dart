import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.amount,
    required super.date,
    required super.householdId,
    required super.categoryId,
    required super.createdAt,
    super.description,
    super.userUuid,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: (json['id'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      householdId: (json['household_id'] as num).toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      userUuid: json['user_uuid'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'household_id': householdId,
      'category_id': categoryId,
      'user_uuid': userUuid,
    };
  }
}
