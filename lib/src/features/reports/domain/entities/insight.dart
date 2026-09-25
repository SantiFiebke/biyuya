import 'package:equatable/equatable.dart';

/// Cambio significativo de una categoría respecto del mes anterior.
class Insight extends Equatable {
  const Insight({
    required this.categoryId,
    required this.categoryName,
    required this.currentAmount,
    required this.previousAmount,
    required this.changePct,
    required this.isIncrease,
    this.categoryColor,
    this.categoryIcon,
  });

  final int categoryId;
  final String categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final double currentAmount;
  final double previousAmount;

  /// ((current - previous) / previous) * 100
  final double changePct;
  final bool isIncrease;

  /// currentAmount - previousAmount, útil para ordenar.
  double get delta => currentAmount - previousAmount;

  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    categoryColor,
    categoryIcon,
    currentAmount,
    previousAmount,
    changePct,
    isIncrease,
  ];
}
