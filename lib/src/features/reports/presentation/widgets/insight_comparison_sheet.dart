import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/core/presentation/widgets/category_avatar.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/reports/domain/entities/insight.dart';
import 'package:biyuya/src/features/reports/domain/insight_expense_diff.dart';
import 'package:biyuya/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Bottom sheet comparativo de un [Insight]: gastos del mes actual vs los
/// del mes anterior en la misma categoría, con etiquetas `Nuevo`/`Grande`.
class InsightComparisonSheet extends ConsumerWidget {
  const InsightComparisonSheet({
    required this.insight,
    required this.year,
    required this.month,
    super.key,
  });

  final Insight insight;
  final int year;
  final int month;

  static Future<void> show(
    BuildContext context, {
    required Insight insight,
    required int year,
    required int month,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) =>
          InsightComparisonSheet(insight: insight, year: year, month: month),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allExpenses = ref.watch(expenseControllerProvider).value ?? [];
    final inCategory = allExpenses
        .where((e) => e.categoryId == insight.categoryId)
        .toList();

    final current = inCategory
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
    // Enero vuelve a diciembre del año anterior.
    final previousYear = month == 1 ? year - 1 : year;
    final previousMonth = month == 1 ? 12 : month - 1;
    final previous = inCategory
        .where(
          (e) => e.date.year == previousYear && e.date.month == previousMonth,
        )
        .toList();

    return _InsightComparisonContent(
      insight: insight,
      current: current,
      previous: previous,
      tags: classifyInsightExpenses(current: current, previous: previous),
    );
  }
}

class _InsightComparisonContent extends StatelessWidget {
  const _InsightComparisonContent({
    required this.insight,
    required this.current,
    required this.previous,
    required this.tags,
  });

  final Insight insight;
  final List<Expense> current;
  final List<Expense> previous;
  final Map<int, Set<ExpenseDiffTag>> tags;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _InsightComparisonHeader(insight: insight),
          const Divider(height: 24),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                _InsightExpenseSection(
                  title: 'Este mes',
                  emptyLabel: 'Sin gastos este mes',
                  expenses: current,
                  tags: tags,
                ),
                const SizedBox(height: 16),
                _InsightExpenseSection(
                  title: 'Mes anterior',
                  emptyLabel: 'Sin gastos el mes anterior',
                  expenses: previous,
                  tags: const {},
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightComparisonHeader extends StatelessWidget {
  const _InsightComparisonHeader({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        parseCategoryColor(insight.categoryColor) ?? theme.colorScheme.primary;
    final icon = iconFromCodePoint(insight.categoryIcon);
    final appColors = theme.extension<AppColors>();
    final changeColor = insight.isIncrease
        ? (appColors?.expense ?? theme.colorScheme.error)
        : (appColors?.income ?? theme.colorScheme.tertiary);
    final pct = insight.changePct.abs().toStringAsFixed(0);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryAvatar(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.categoryName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('Este mes ', style: muted),
                    AmountText(
                      amount: insight.currentAmount,
                      style: theme.textTheme.bodySmall,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    Text(' vs ', style: muted),
                    AmountText(
                      amount: insight.previousAmount,
                      style: theme.textTheme.bodySmall,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${insight.isIncrease ? '+' : '-'}$pct%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: changeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightExpenseSection extends StatelessWidget {
  const _InsightExpenseSection({
    required this.title,
    required this.emptyLabel,
    required this.expenses,
    required this.tags,
  });

  final String title;
  final String emptyLabel;
  final List<Expense> expenses;
  final Map<int, Set<ExpenseDiffTag>> tags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final subtotal = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    if (expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(title: title),
            const SizedBox(height: 8),
            Text(
              emptyLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SectionTitle(title: title, subtotal: subtotal),
        ),
        ...expenses.map(
          (expense) => _InsightExpenseRow(
            expense: expense,
            dateFormat: dateFormat,
            tags: tags[expense.id] ?? const <ExpenseDiffTag>{},
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtotal});

  final String title;
  final double? subtotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (subtotal != null)
          AmountText(
            amount: subtotal!,
            style: Theme.of(context).textTheme.titleSmall,
          ),
      ],
    );
  }
}

class _InsightExpenseRow extends StatelessWidget {
  const _InsightExpenseRow({
    required this.expense,
    required this.dateFormat,
    required this.tags,
  });

  final Expense expense;
  final DateFormat dateFormat;
  final Set<ExpenseDiffTag> tags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Orden fijo de etiquetas: nuevo primero, grande después.
    final orderedTags = ExpenseDiffTag.values.where(tags.contains);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(expense.description ?? 'Sin descripción'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              dateFormat.format(expense.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            ...orderedTags.map(
              (tag) => _DiffTagChip(
                label: tag == ExpenseDiffTag.nuevo ? 'Nuevo' : 'Grande',
              ),
            ),
          ],
        ),
      ),
      trailing: AmountText(
        amount: expense.amount,
        style: theme.textTheme.titleSmall,
      ),
    );
  }
}

/// Chip muted, mismo estilo que 'No es gasto' en report_view.
class _DiffTagChip extends StatelessWidget {
  const _DiffTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
