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
  });

  final int categoryId;
  final String categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final double amount;
  final double percentage;
  final double? budgetAmount;

  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    amount,
    percentage,
    categoryColor,
    categoryIcon,
    budgetAmount,
  ];
}
