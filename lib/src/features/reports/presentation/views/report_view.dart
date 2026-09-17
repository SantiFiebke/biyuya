import 'dart:async';

import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/report_controller.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/category_expenses_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

const _monthNames = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

class ReportView extends ConsumerWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReport = ref.watch(reportControllerProvider);

    ref.listen<AsyncValue<MonthlyReport?>>(reportControllerProvider, (
      _,
      state,
    ) {
      state.whenOrNull(
        error: (error, _) => context.showErrorSnackBar(error.toString()),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: asyncReport.when(
        loading: () => const ReportSkeleton(),
        error: (error, _) => Center(
          child: Text(
            'Error al cargar reporte',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        data: (report) {
          if (report == null) {
            return const Center(child: Text('No hay datos para este mes'));
          }
          return ReportContent(
            report: report,
            onCategoryTap: (breakdown) {
              unawaited(
                CategoryExpensesSheet.show(
                  context,
                  breakdown: breakdown,
                  year: report.year,
                  month: report.month,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ReportContent extends StatelessWidget {
  const ReportContent({
    required this.report,
    required this.onCategoryTap,
    super.key,
  });

  final MonthlyReport report;
  final void Function(CategoryBreakdown breakdown) onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final amountFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: r'$',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MonthNavigator(),
          const SizedBox(height: 24),
          SummaryCard(
            total: report.total,
            previousTotal: report.previousTotal,
            variation: report.variation,
            amountFormat: amountFormat,
          ),
          const SizedBox(height: 24),
          Text(
            'Desglose por categoría',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (report.categoryBreakdowns.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No hay gastos este mes'),
              ),
            )
          else
            ...report.categoryBreakdowns.map(
              (breakdown) => CategoryBreakdownTile(
                breakdown: breakdown,
                amountFormat: amountFormat,
                onTap: () => onCategoryTap(breakdown),
              ),
            ),
        ],
      ),
    );
  }
}

class MonthNavigator extends ConsumerWidget {
  const MonthNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportControllerProvider).value;
    final controller = ref.read(reportControllerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: controller.previousMonth,
        ),
        Text(
          report != null
              ? '${_monthNames[report.month - 1]} ${report.year}'
              : 'Cargando...',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: controller.canGoNext ? controller.nextMonth : null,
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.total,
    required this.previousTotal,
    required this.variation,
    required this.amountFormat,
    super.key,
  });

  final double total;
  final double previousTotal;
  final double variation;
  final NumberFormat amountFormat;

  @override
  Widget build(BuildContext context) {
    final isIncrease = variation > 0;
    final variationColor = isIncrease ? Colors.red : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Total del mes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              amountFormat.format(total),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (previousTotal > 0) ...[
              const SizedBox(height: 12),
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
                    '${isIncrease ? '+' : ''}${variation.toStringAsFixed(1)}% vs mes anterior',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: variationColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CategoryBreakdownTile extends StatelessWidget {
  const CategoryBreakdownTile({
    required this.breakdown,
    required this.amountFormat,
    this.onTap,
    super.key,
  });

  final CategoryBreakdown breakdown;
  final NumberFormat amountFormat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        parseCategoryColor(breakdown.categoryColor) ??
        Theme.of(context).colorScheme.primary;
    final icon = iconFromCodePoint(breakdown.categoryIcon);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(breakdown.categoryName),
        subtitle: Text('${breakdown.percentage.toStringAsFixed(1)}%'),
        trailing: Text(
          amountFormat.format(breakdown.amount),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class ReportSkeleton extends StatelessWidget {
  const ReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.chevron_left),
                Container(width: 200, height: 28, color: Colors.grey.shade300),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 16,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              3,
              (_) => Card(
                child: ListTile(
                  leading: const CircleAvatar(radius: 20),
                  title: Container(
                    width: 120,
                    height: 16,
                    color: Colors.grey.shade300,
                  ),
                  trailing: Container(
                    width: 80,
                    height: 16,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
