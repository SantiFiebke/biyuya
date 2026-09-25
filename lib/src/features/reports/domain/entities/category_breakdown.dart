import 'package:equatable/equatable.dart';

class CategoryBreakdown extends Equatable {
  const CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    this.categoryColor,
    this.categoryIcon,
    this.budgetAmount,
    this.previousAmount = 0,
  });

  final int categoryId;
  final String categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final double amount;
  final double percentage;
  final double? budgetAmount;

  /// Total del mismo mes anterior. 0 si la categoría no tuvo gastos entonces.
  final double previousAmount;

  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    amount,
    percentage,
    categoryColor,
    categoryIcon,
    budgetAmount,
    previousAmount,
  ];
}
