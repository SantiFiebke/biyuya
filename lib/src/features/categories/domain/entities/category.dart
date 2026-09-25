import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.householdId,
    required this.createdAt,
    this.color,
    this.icon,
    this.budgetAmount,
    this.isExpense = true,
  });

  final int id;
  final String name;
  final String? color;
  final String? icon;
  final int householdId;
  final DateTime createdAt;
  final double? budgetAmount;

  /// false = income/transfer style category; excluded from expense totals.
  final bool isExpense;

  @override
  List<Object?> get props => [
    id,
    name,
    color,
    icon,
    householdId,
    createdAt,
    budgetAmount,
    isExpense,
  ];
}
