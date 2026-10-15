import 'package:equatable/equatable.dart';

enum WeeklyBudgetStatus { ok, warning, exceeded }

class WeeklyCategoryBreakdown extends Equatable {
  const WeeklyCategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.weeklyBudget,
    required this.deviation,
    required this.status,
    this.categoryColor,
    this.categoryIcon,
    this.isExpense = true,
    this.hasBudget = true,
  });

  /// Construye el desglose semanal derivando el presupuesto semanal
  /// (`budgetAmount / weeksPerMonth`) y el estado de alerta.
  /// Sin presupuesto (`null` o `<= 0`): weeklyBudget 0, status ok,
  /// `hasBudget` false — la UI omite el semáforo.
  factory WeeklyCategoryBreakdown.fromBudget({
    required int categoryId,
    required String categoryName,
    required double amount,
    required double? budgetAmount,
    String? categoryColor,
    String? categoryIcon,
    bool isExpense = true,
  }) {
    final hasBudget = budgetAmount != null && budgetAmount > 0;
    final weeklyBudget = hasBudget ? budgetAmount / weeksPerMonth : 0.0;
    return WeeklyCategoryBreakdown(
      categoryId: categoryId,
      categoryName: categoryName,
      categoryColor: categoryColor,
      categoryIcon: categoryIcon,
      amount: amount,
      weeklyBudget: weeklyBudget,
      deviation: amount - weeklyBudget,
      status: hasBudget
          ? computeStatus(amount: amount, weeklyBudget: weeklyBudget)
          : WeeklyBudgetStatus.ok,
      hasBudget: hasBudget,
      isExpense: isExpense,
    );
  }

  /// Semanas promedio por mes (365.25 días / 7 / 12 ≈ 4.33).
  static const double weeksPerMonth = 4.33;

  /// exceeded si `amount > weeklyBudget`; warning si
  /// `amount > weeklyBudget * 0.85`; si no, ok.
  static WeeklyBudgetStatus computeStatus({
    required double amount,
    required double weeklyBudget,
  }) {
    if (amount > weeklyBudget) {
      return WeeklyBudgetStatus.exceeded;
    }
    if (amount > weeklyBudget * 0.85) {
      return WeeklyBudgetStatus.warning;
    }
    return WeeklyBudgetStatus.ok;
  }

  final int categoryId;
  final String categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final double amount;
  final double weeklyBudget;

  /// amount - weeklyBudget. Positivo = sobre presupuesto.
  final double deviation;
  final WeeklyBudgetStatus status;

  /// false = categoría no-gasto (ingreso/transferencia).
  final bool isExpense;

  /// false = sin presupuesto cargado (`budgetAmount` null o <= 0):
  /// no hay semáforo ni desvío meaningful que mostrar.
  final bool hasBudget;

  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    categoryColor,
    categoryIcon,
    amount,
    weeklyBudget,
    deviation,
    status,
    isExpense,
    hasBudget,
  ];
}
