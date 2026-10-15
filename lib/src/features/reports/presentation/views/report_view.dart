import 'dart:async';

import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/core/presentation/widgets/category_avatar.dart';
import 'package:biyuya/src/core/presentation/widgets/empty_view.dart';
import 'package:biyuya/src/core/presentation/widgets/error_view.dart';
import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/insight.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/domain/insights.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/report_controller.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/savings_report_controller.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/weekly_report_controller.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/budget_progress_section.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/category_expenses_sheet.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/insight_comparison_sheet.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/insights_section.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/savings_section.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/weekly_tracking_section.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:biyuya/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    void showError(Object error) => context.showErrorSnackBar(error.toString());

    // Cascade: lint `cascade_invocations` pide un solo receptor `ref`.
    // Secciones secundarias se ocultan en error (shrink); el feedback va por
    // snackbar, igual que el reporte mensual.
    ref
      ..listen<AsyncValue<ReportState>>(reportControllerProvider, (_, state) {
        state.whenOrNull(error: (error, _) => showError(error));
      })
      ..listen(weeklyReportControllerProvider, (_, state) {
        state.whenOrNull(error: (error, _) => showError(error));
      })
      ..listen(savingsReportControllerProvider, (_, state) {
        state.whenOrNull(error: (error, _) => showError(error));
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: asyncReport.when(
        loading: () => const ReportSkeleton(),
        error: (_, _) => ErrorView(
          message: 'No se pudo cargar el reporte',
          retryLabel: 'Reintentar',
          onRetry: () => ref.invalidate(reportControllerProvider),
        ),
        data: (reportState) {
          final report = reportState.report;
          if (report == null) {
            return EmptyView(
              title: 'Sin datos este mes',
              message: 'Registrá gastos para ver tus reportes',
              actionLabel: 'Registrar gasto',
              onAction: () => context.push(AppRoute.expenseNew.path),
            );
          }
          // report no-null acá (guard arriba): insights del mes vs anterior.
          final insights = generateInsights(report: report);
          return ReportContent(
            report: report,
            insights: insights,
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
            onInsightTap: (insight) {
              unawaited(
                InsightComparisonSheet.show(
                  context,
                  insight: insight,
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
    required this.insights,
    required this.onCategoryTap,
    this.onInsightTap,
    super.key,
  });

  final MonthlyReport report;
  final List<Insight> insights;
  final void Function(CategoryBreakdown breakdown) onCategoryTap;
  final void Function(Insight insight)? onInsightTap;

  @override
  Widget build(BuildContext context) {
    // Desglose puede incluir categorías solo del mes anterior (amount 0):
    // tiles/empty-state solo muestran gastos del mes actual.
    // No-gastos van al final (amount desc); gastos primero (amount desc).
    final visibleBreakdowns =
        report.categoryBreakdowns
            .where((breakdown) => breakdown.amount > 0)
            .toList()
          ..sort((a, b) {
            if (a.isExpense != b.isExpense) {
              return a.isExpense ? -1 : 1;
            }
            return b.amount.compareTo(a.amount);
          });
    // Mes sin gasto genera insights -100% (ruido) → no mostrar sección.
    final showInsights = report.total > 0 && insights.isNotEmpty;
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
          ),
          const SizedBox(height: 24),
          Text(
            'Desglose por categoría',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (visibleBreakdowns.isEmpty)
            const EmptyView(
              title: 'No hay gastos este mes',
              message: 'Registrá gastos para ver el desglose por categoría',
            )
          else
            ...visibleBreakdowns.map(
              (breakdown) => CategoryBreakdownTile(
                breakdown: breakdown,
                onTap: () => onCategoryTap(breakdown),
              ),
            ),
          if (showInsights) ...[
            const SizedBox(height: 24),
            InsightsSection(insights: insights, onInsightTap: onInsightTap),
          ],
          // Presupuestos traen su propio espacio superior (shrink sin hueco).
          BudgetProgressSection(breakdowns: report.categoryBreakdowns),
          const SizedBox(height: 24),
          const WeeklyReportSection(),
          const SizedBox(height: 24),
          const SavingsReportSection(),
        ],
      ),
    );
  }
}

/// Sección semanal ligada a su controller: maneja su propio `AsyncValue`
/// (loading/error → shrink, el error además snackbar en `ReportView`) para no
/// tocar el skeleton/error del reporte mensual.
class WeeklyReportSection extends ConsumerWidget {
  const WeeklyReportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWeekly = ref.watch(weeklyReportControllerProvider);
    final controller = ref.read(weeklyReportControllerProvider.notifier);

    return asyncWeekly.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) {
        final report = state.report;
        if (report == null) {
          return const SizedBox.shrink();
        }
        return WeeklyTrackingSection(
          report: report,
          onPreviousWeek: controller.previousWeek,
          onNextWeek: controller.canGoNext ? controller.nextWeek : null,
        );
      },
      // Mantiene el reporte anterior visible durante reload/refresh.
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }
}

/// Sección de ahorro ligada a su controller. Mismo manejo de `AsyncValue`
/// que [WeeklyReportSection].
class SavingsReportSection extends ConsumerWidget {
  const SavingsReportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSavings = ref.watch(savingsReportControllerProvider);

    return asyncSavings.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) {
        final report = state.report;
        if (report == null) {
          return const SizedBox.shrink();
        }
        return SavingsSection(report: report);
      },
      // Mantiene el reporte anterior visible durante reload/refresh.
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }
}

class MonthNavigator extends ConsumerWidget {
  const MonthNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reportControllerProvider).value;
    final controller = ref.read(reportControllerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: controller.previousMonth,
        ),
        Text(
          selected != null
              ? '${_monthNames[selected.month - 1]} ${selected.year}'
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
    super.key,
  });

  final double total;
  final double previousTotal;
  final double variation;

  @override
  Widget build(BuildContext context) {
    final isIncrease = variation > 0;
    final appColors = Theme.of(context).extension<AppColors>();
    final variationColor = isIncrease
        ? (appColors?.expense ?? Theme.of(context).colorScheme.error)
        : (appColors?.income ?? Theme.of(context).colorScheme.primary);

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
            AmountText(
              amount: total,
              style: Theme.of(context).textTheme.headlineLarge,
              color: Theme.of(context).colorScheme.primary,
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
  const CategoryBreakdownTile({required this.breakdown, this.onTap, super.key});

  final CategoryBreakdown breakdown;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        parseCategoryColor(breakdown.categoryColor) ??
        Theme.of(context).colorScheme.primary;
    final icon = iconFromCodePoint(breakdown.categoryIcon);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: onTap,
            leading: CategoryAvatar(icon: icon, color: color),
            title: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(breakdown.categoryName),
                if (!breakdown.isExpense) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'No es gasto',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: breakdown.isExpense
                ? Text('${breakdown.percentage.toStringAsFixed(1)}%')
                : null,
            trailing: AmountText(
              amount: breakdown.amount,
              style: Theme.of(context).textTheme.titleSmall,
              color: breakdown.isExpense
                  ? null
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportSkeleton extends StatelessWidget {
  const ReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      effect: ShimmerEffect(
        baseColor: Theme.of(context).colorScheme.primary.withAlpha(10),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.chevron_left),
                Container(
                  width: 200,
                  height: 28,
                  // decoration: BoxDecoration(
                  //   borderRadius: BorderRadius.circular(8),
                  // ),
                  color: Colors.grey,
                ),
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
