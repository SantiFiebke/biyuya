import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/core/presentation/widgets/category_avatar.dart';
import 'package:biyuya/src/features/reports/domain/entities/insight.dart';
import 'package:biyuya/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Sección "Insights del mes". Dumb widget: sin providers, recibe la lista
/// ya calculada.
class InsightsSection extends StatelessWidget {
  const InsightsSection({required this.insights, this.onInsightTap, super.key});

  final List<Insight> insights;
  final void Function(Insight insight)? onInsightTap;

  @override
  Widget build(BuildContext context) {
    // Guard ya aplicado en ReportContent; esto es defensa en profundidad.
    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Insights del mes',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...insights.map(
          (insight) => InsightCard(
            insight: insight,
            onTap: onInsightTap == null ? null : () => onInsightTap!(insight),
          ),
        ),
      ],
    );
  }
}

class InsightCard extends StatelessWidget {
  const InsightCard({required this.insight, this.onTap, super.key});

  final Insight insight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        parseCategoryColor(insight.categoryColor) ?? theme.colorScheme.primary;
    final icon = iconFromCodePoint(insight.categoryIcon);
    final appColors = theme.extension<AppColors>();
    final changeColor = insight.isIncrease
        ? (appColors?.expense ?? theme.colorScheme.error)
        : (appColors?.income ?? theme.colorScheme.primary);
    final pct = insight.changePct.abs().toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      // onTap null → InkWell sin splash: mismo look que antes.
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CategoryAvatar(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${insight.categoryName}: '
                      '${insight.isIncrease ? '+' : '-'}$pct% vs mes anterior',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AmountText(
                          amount: insight.previousAmount,
                          style: theme.textTheme.bodySmall,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        Text(
                          ' → ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        AmountText(
                          amount: insight.currentAmount,
                          style: theme.textTheme.bodySmall,
                          color: changeColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${insight.isIncrease ? '+' : '-'}$pct%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: changeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
