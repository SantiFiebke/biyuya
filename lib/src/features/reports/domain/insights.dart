import 'package:biyuya/src/features/reports/domain/entities/insight.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';

/// Genera insights comparando cada categoría del mes actual contra el mes
/// anterior. Función pura: sin estado, sin I/O.
///
/// Reglas:
/// - Solo categorías con `previousAmount > 0` (sin base no hay % confiable).
/// - Filtra por `|changePct| >= thresholdPct` y `|delta| >= minDelta`.
/// - Ordena por `|amount - previousAmount|` descendente.
List<Insight> generateInsights({
  required MonthlyReport report,
  double thresholdPct = 20,
  double minDelta = 0,
}) {
  final insights = <Insight>[];

  for (final breakdown in report.categoryBreakdowns) {
    final previousAmount = breakdown.previousAmount;
    if (previousAmount <= 0) {
      continue;
    }

    final delta = breakdown.amount - previousAmount;
    final changePct = (delta / previousAmount) * 100;

    if (changePct.abs() < thresholdPct) {
      continue;
    }
    if (delta.abs() < minDelta) {
      continue;
    }

    insights.add(
      Insight(
        categoryId: breakdown.categoryId,
        categoryName: breakdown.categoryName,
        categoryColor: breakdown.categoryColor,
        categoryIcon: breakdown.categoryIcon,
        currentAmount: breakdown.amount,
        previousAmount: previousAmount,
        changePct: changePct,
        isIncrease: changePct > 0,
      ),
    );
  }

  insights.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));

  return insights;
}
