import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/core/presentation/widgets/category_avatar.dart';
import 'package:biyuya/src/features/reports/domain/entities/weekly_category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/weekly_report.dart';
import 'package:biyuya/theme/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

String _semaphore(WeeklyBudgetStatus status) => switch (status) {
  WeeklyBudgetStatus.ok => '🟢',
  WeeklyBudgetStatus.warning => '🟡',
  WeeklyBudgetStatus.exceeded => '🔴',
};

/// Sección "Seguimiento semanal". Dumb widget: recibe el reporte y los
/// callbacks de navegación por constructor, sin providers ni lógica.
class WeeklyTrackingSection extends StatelessWidget {
  const WeeklyTrackingSection({
    required this.report,
    this.onPreviousWeek,
    this.onNextWeek,
    super.key,
  });

  final WeeklyReport report;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM');
    // weekEnd es exclusivo (lunes siguiente): el último día real es domingo.
    final lastDay = report.weekEnd.subtract(const Duration(days: 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPreviousWeek,
            ),
            Column(
              children: [
                Text(
                  'Semana ${report.week}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${dateFormat.format(report.weekStart)} – '
                  '${dateFormat.format(lastDay)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNextWeek,
            ),
          ],
        ),
        const SizedBox(height: 8),
        WeeklySummaryCard(report: report),
        const SizedBox(height: 8),
        ...report.breakdowns.map(
          (breakdown) => WeeklyCategoryCard(breakdown: breakdown),
        ),
      ],
    );
  }
}

/// Total de la semana, variación vs semana anterior y comparación visual.
class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({required this.report, super.key});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>();
    final isIncrease = report.isIncrease;
    final variationColor = isIncrease
        ? (appColors?.expense ?? theme.colorScheme.error)
        : (appColors?.income ?? theme.colorScheme.primary);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Total de la semana',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 8),
            AmountText(
              amount: report.total,
              style: theme.textTheme.headlineSmall,
              color: theme.colorScheme.primary,
            ),
            if (report.hasPreviousData) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isIncrease ? Icons.trending_up : Icons.trending_down,
                    color: variationColor,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isIncrease ? '+' : ''}'
                    '${report.variation.toStringAsFixed(1)}% vs semana anterior',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: variationColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              WeekComparisonChart(
                previousTotal: report.previousWeekTotal,
                currentTotal: report.total,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Comparación compacta: semana anterior vs actual. Dumb: sólo valores.
/// ponytail: WeeklyReport no trae serie diaria; si aparece, cambiar por
/// sparkline de 7 puntos.
class WeekComparisonChart extends StatelessWidget {
  const WeekComparisonChart({
    required this.previousTotal,
    required this.currentTotal,
    super.key,
  });

  static const _labels = ['Anterior', 'Actual'];

  final double previousTotal;
  final double currentTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>();
    final currentColor = appColors?.expense ?? theme.colorScheme.error;
    final previousColor = theme.colorScheme.surfaceContainerHighest;

    return SizedBox(
      height: 96,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: const BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= _labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _labels[index],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: previousTotal,
                  color: previousColor,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: currentTotal,
                  color: currentColor.withValues(alpha: 0.85),
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Categoría semanal: monto, presupuesto semanal, desvío y semáforo.
class WeeklyCategoryCard extends StatelessWidget {
  const WeeklyCategoryCard({required this.breakdown, super.key});

  final WeeklyCategoryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>();
    final color =
        parseCategoryColor(breakdown.categoryColor) ??
        theme.colorScheme.primary;
    final icon = iconFromCodePoint(breakdown.categoryIcon);
    final muted = theme.colorScheme.onSurfaceVariant;
    final over = breakdown.deviation > 0;
    final deviationColor = over
        ? (appColors?.expense ?? theme.colorScheme.error)
        : (appColors?.income ?? theme.colorScheme.primary);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CategoryAvatar(icon: icon, color: color, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      // Sin presupuesto no hay estado que señalar.
                      if (breakdown.hasBudget)
                        Text(_semaphore(breakdown.status)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      AmountText(
                        amount: breakdown.amount,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(' de ', style: theme.textTheme.bodySmall),
                      AmountText(
                        amount: breakdown.weeklyBudget,
                        style: theme.textTheme.bodySmall,
                        color: muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        over ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: deviationColor,
                      ),
                      const SizedBox(width: 4),
                      AmountText(
                        amount: breakdown.deviation,
                        style: theme.textTheme.bodySmall,
                        color: deviationColor,
                        showSign: true,
                      ),
                      Text(
                        ' vs presupuesto',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
