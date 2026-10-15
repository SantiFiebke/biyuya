import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/features/reports/domain/entities/savings_report.dart';
import 'package:biyuya/theme/theme.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Sección "Ahorro del mes". Dumb widget: recibe el reporte ya calculado,
/// sin providers ni lógica de negocio.
class SavingsSection extends StatelessWidget {
  const SavingsSection({required this.report, super.key});

  final SavingsReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>();
    final savingsColor = appColors?.income ?? theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurfaceVariant;
    final goal = report.goalAmount;
    final ratio = goal > 0 ? report.totalSaved / goal : 0.0;
    final pctLabel = goal > 0
        ? '${report.progressPct.toStringAsFixed(0)}%'
        : '0%';
    final dateFormat = DateFormat('dd/MM');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ahorro del mes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Total ahorrado',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 4),
            AmountText(
              amount: report.totalSaved,
              style: theme.textTheme.headlineSmall,
              color: savingsColor,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                color: savingsColor,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Meta: ', style: theme.textTheme.bodySmall),
                      AmountText(
                        amount: goal,
                        style: theme.textTheme.bodySmall,
                        color: muted,
                      ),
                      Text(
                        ' (3 meses de gastos)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  pctLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: savingsColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (report.entries.isEmpty)
              Text(
                'Sin ahorros este mes',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              )
            else ...[
              const Divider(height: 1),
              const SizedBox(height: 8),
              for (final entry in report.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          dateFormat.format(entry.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.description ??
                              entry.source ??
                              'Sin descripción',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AmountText(
                        amount: entry.amount,
                        style: theme.textTheme.bodySmall,
                        color: savingsColor,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
