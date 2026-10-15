import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/weekly_category_breakdown.dart';
import 'package:biyuya/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Sección "Presupuestos". Dumb widget: recibe los desgloses por constructor
/// y sólo renderiza los que tienen presupuesto cargado.
class BudgetProgressSection extends StatelessWidget {
  const BudgetProgressSection({required this.breakdowns, super.key});

  final List<CategoryBreakdown> breakdowns;

  @override
  Widget build(BuildContext context) {
    final withBudget = breakdowns
        .where(
          (breakdown) =>
              breakdown.isExpense &&
              breakdown.budgetAmount != null &&
              breakdown.budgetAmount! > 0,
        )
        .toList();
    if (withBudget.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Espacio propio de la sección: si no hay presupuestos, el shrink
        // de arriba evita dejar un hueco de sobra.
        const SizedBox(height: 24),
        Text(
          'Presupuestos',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...withBudget.map(
          (breakdown) => BudgetProgressRow(breakdown: breakdown),
        ),
      ],
    );
  }
}

/// Barra de progreso de una categoría: % usado, monto/presupuesto y
/// disponible. El color sale del estado ok/warning/exceeded.
class BudgetProgressRow extends StatelessWidget {
  const BudgetProgressRow({required this.breakdown, super.key});

  final CategoryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>();
    final muted = theme.colorScheme.onSurfaceVariant;
    final budget = breakdown.budgetAmount ?? 0;
    final ratio = budget > 0 ? breakdown.amount / budget : 0.0;
    final remaining = budget - breakdown.amount;
    final pctLabel = '${(ratio * 100).toStringAsFixed(0)}%';
    // Umbrales (0.85 / 1.0) reutilizados de la entidad semanal.
    final status = WeeklyCategoryBreakdown.computeStatus(
      amount: breakdown.amount,
      weeklyBudget: budget,
    );
    final stateColor = switch (status) {
      WeeklyBudgetStatus.ok => appColors?.income ?? theme.colorScheme.primary,
      WeeklyBudgetStatus.warning => Colors.amber.shade600,
      WeeklyBudgetStatus.exceeded =>
        appColors?.expense ?? theme.colorScheme.error,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    breakdown.categoryName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  pctLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: stateColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                color: stateColor,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    AmountText(
                      amount: breakdown.amount,
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(' / ', style: theme.textTheme.bodySmall),
                    AmountText(
                      amount: budget,
                      style: theme.textTheme.bodySmall,
                      color: muted,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      remaining >= 0 ? 'Disponible' : 'Excedido',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    const SizedBox(width: 4),
                    AmountText(
                      amount: remaining,
                      style: theme.textTheme.bodySmall,
                      color: stateColor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
