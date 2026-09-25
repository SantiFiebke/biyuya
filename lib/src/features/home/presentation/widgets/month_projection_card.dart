import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/features/reports/domain/month_projection.dart';
import 'package:material_ui/material_ui.dart';

/// Tile compacto con la proyección de gasto al fin del mes.
class MonthProjectionCard extends StatelessWidget {
  const MonthProjectionCard({
    required this.spentSoFar,
    required this.referenceDate,
    super.key,
  });

  final double spentSoFar;
  final DateTime referenceDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final projected = projectMonthEnd(
      spentSoFar: spentSoFar,
      referenceDate: referenceDate,
    );
    final daysInMonth = DateTime(
      referenceDate.year,
      referenceDate.month + 1,
      0,
    ).day;
    final daysLeft = daysInMonth - referenceDate.day;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Proyección fin de mes',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    daysLeft == 1
                        ? '1 día restante'
                        : '$daysLeft días restantes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AmountText(amount: projected, style: theme.textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
