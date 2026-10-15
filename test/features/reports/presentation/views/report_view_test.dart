import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/provider/categories_provider.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/insight.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/report_controller.dart';
import 'package:biyuya/src/features/reports/presentation/views/report_view.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/budget_progress_section.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/insights_section.dart';
import 'package:biyuya/src/features/reports/provider/report_repository_provider.dart';
import 'package:biyuya/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

// Session without household → ReportController keeps AsyncData(null).
class _NoHouseholdAuthSession extends AuthSessionController {
  @override
  FutureOr<UserProfile?> build() =>
      const UserProfile(id: 'test-user-id', name: 'Test', lastName: 'User');
}

/// Stuck in AsyncLoading with no previous value → exercises the skeleton
/// branch (the real controller always seeds AsyncData, so `when` skips
/// loading on refresh).
class _StuckReportController extends ReportController {
  @override
  AsyncValue<ReportState> build() => const AsyncLoading<ReportState>();
}

const _testReport = MonthlyReport(
  total: 1000,
  previousTotal: 800,
  variation: 25,
  categoryBreakdowns: [
    CategoryBreakdown(
      categoryId: 1,
      categoryName: 'Food',
      amount: 600,
      percentage: 60,
      categoryColor: '#4CAF50',
      categoryIcon: '63046',
    ),
    CategoryBreakdown(
      categoryId: 2,
      categoryName: 'Transport',
      amount: 400,
      percentage: 40,
      categoryColor: '#2196F3',
      categoryIcon: '57681',
    ),
  ],
  year: 2025,
  month: 7,
);

void main() {
  late MockReportRepository mockRepo;

  final theme = MaterialTheme(ThemeData().textTheme).light();

  CategoryBreakdown breakdown({
    double amount = 600,
    double? budgetAmount,
    double previousAmount = 0,
    bool isExpense = true,
  }) {
    return CategoryBreakdown(
      categoryId: 1,
      categoryName: 'Food',
      amount: amount,
      percentage: 60,
      categoryColor: '#4CAF50',
      categoryIcon: '63046',
      budgetAmount: budgetAmount,
      previousAmount: previousAmount,
      isExpense: isExpense,
    );
  }

  setUp(() {
    mockRepo = MockReportRepository();
    when(
      () => mockRepo.getMonthlyReport(
        householdId: any(named: 'householdId'),
        year: any(named: 'year'),
        month: any(named: 'month'),
        categories: any(named: 'categories'),
      ),
    ).thenAnswer((_) async => const Success(_testReport));
  });

  List<Override> defaultOverrides() => [
    reportRepositoryProvider.overrideWithValue(mockRepo),
    authSessionControllerProvider.overrideWith(FakeAuthSessionController.new),
    // ReportController resolves categories via categoriesProvider; stub it so
    // the real Supabase-backed repository is never touched.
    categoriesProvider.overrideWith((ref) async => const <Category>[]),
  ];

  Future<void> pumpReport(WidgetTester tester) async {
    await tester.pumpWidget(
      wrapTest(
        child: const ReportView(),
        overrides: defaultOverrides(),
        theme: theme,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  void stubReport(MonthlyReport report) {
    when(
      () => mockRepo.getMonthlyReport(
        householdId: any(named: 'householdId'),
        year: any(named: 'year'),
        month: any(named: 'month'),
        categories: any(named: 'categories'),
      ),
    ).thenAnswer((_) async => Success(report));
  }

  group('ReportView', () {
    testWidgets('renders app bar with title Reportes', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ReportView(), overrides: defaultOverrides()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Reportes'), findsOneWidget);
    });

    testWidgets('renders month selector with chevron icons', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ReportView(), overrides: defaultOverrides()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders summary card with total', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ReportView(), overrides: defaultOverrides()),
      );
      // Controller fires unawaited(Future.microtask(_loadReport)) in build()
      // Need multiple pumps: initial build → microtask → async result → state update → rebuild
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Total del mes'), findsOneWidget);
      // AmountText renders a RichText, so find.text('1.000') no longer matches.
      final amountText = tester.widget<AmountText>(
        find.descendant(
          of: find.byType(SummaryCard),
          matching: find.byType(AmountText),
        ),
      );
      expect(amountText.amount, 1000);
    });

    testWidgets('shows ReportSkeleton when loading', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ReportView(),
          overrides: [
            ...defaultOverrides(),
            // Stuck in AsyncLoading with no previous value → skeleton branch.
            reportControllerProvider.overrideWith(_StuckReportController.new),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(ReportSkeleton), findsOneWidget);
    });

    testWidgets('shows error text on failure', (tester) async {
      when(
        () => mockRepo.getMonthlyReport(
          householdId: any(named: 'householdId'),
          year: any(named: 'year'),
          month: any(named: 'month'),
          categories: any(named: 'categories'),
        ),
      ).thenAnswer((_) async => const Error(ReportFailure('fail')));

      await tester.pumpWidget(
        wrapTest(child: const ReportView(), overrides: defaultOverrides()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('No se pudo cargar el reporte'), findsOneWidget);
    });

    testWidgets('shows empty state with Registrar gasto CTA when no report', (
      tester,
    ) async {
      // No household in session → controller stays AsyncData(null).
      await tester.pumpWidget(
        wrapTest(
          child: const ReportView(),
          overrides: [
            reportRepositoryProvider.overrideWithValue(mockRepo),
            authSessionControllerProvider.overrideWith(
              _NoHouseholdAuthSession.new,
            ),
            categoriesProvider.overrideWith((ref) async => const <Category>[]),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Sin datos este mes'), findsOneWidget);
      expect(find.text('Registrar gasto'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Registrar gasto'),
        findsOneWidget,
      );
    });

    testWidgets('shows progress bar when breakdown has budget', (tester) async {
      stubReport(
        makeReport(categoryBreakdowns: [breakdown(budgetAmount: 500)]),
      );

      await pumpReport(tester);

      // Budget bar lives in BudgetProgressSection, not in the tile.
      expect(
        find.descendant(
          of: find.byType(BudgetProgressSection),
          matching: find.byType(LinearProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(CategoryBreakdownTile),
          matching: find.byType(LinearProgressIndicator),
        ),
        findsNothing,
      );
    });

    testWidgets('hides progress bar when breakdown has no budget', (
      tester,
    ) async {
      stubReport(makeReport(categoryBreakdowns: [breakdown()]));

      await pumpReport(tester);

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('bar is expense color when ratio exceeds 1', (tester) async {
      stubReport(
        makeReport(categoryBreakdowns: [breakdown(budgetAmount: 500)]),
      );

      await pumpReport(tester);

      final bar = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byType(BudgetProgressSection),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(bar.color, theme.extension<AppColors>()!.expense);
    });

    testWidgets('bar is income color when ratio below 0.75', (tester) async {
      stubReport(
        makeReport(
          categoryBreakdowns: [breakdown(amount: 300, budgetAmount: 500)],
        ),
      );

      await pumpReport(tester);

      final bar = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byType(BudgetProgressSection),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(bar.color, theme.extension<AppColors>()!.income);
    });

    testWidgets('month with 0 current spending hides insights section', (
      tester,
    ) async {
      stubReport(
        makeReport(
          total: 0,
          categoryBreakdowns: [
            const CategoryBreakdown(
              categoryId: 1,
              categoryName: 'Food',
              amount: 0,
              percentage: 0,
              previousAmount: 100,
            ),
          ],
        ),
      );

      await pumpReport(tester);

      expect(find.text('No hay gastos este mes'), findsOneWidget);
      expect(find.text('Insights del mes'), findsNothing);
    });

    testWidgets('shows insights when spending has qualified change', (
      tester,
    ) async {
      // amount 600 vs previous 480 → +25% (>= 20% umbral).
      stubReport(
        makeReport(categoryBreakdowns: [breakdown(previousAmount: 480)]),
      );

      await pumpReport(tester);

      expect(find.text('Desglose por categoría'), findsOneWidget);
      expect(find.text('Insights del mes'), findsOneWidget);
      expect(find.byType(InsightCard), findsOneWidget);
    });

    testWidgets('hides insights when no change qualifies', (tester) async {
      // previousAmount 0 en todas → sin base, ningún insight calificado.
      stubReport(
        makeReport(categoryBreakdowns: [breakdown(), breakdown(amount: 400)]),
      );

      await pumpReport(tester);

      expect(find.text('Desglose por categoría'), findsOneWidget);
      expect(find.byType(CategoryBreakdownTile), findsNWidgets(2));
      expect(find.text('Insights del mes'), findsNothing);
      expect(find.byType(InsightCard), findsNothing);
    });

    testWidgets('hides insights when change is below threshold', (
      tester,
    ) async {
      // 600 vs 550 → +9.1% (< 20% umbral) → ningún insight calificado.
      stubReport(
        makeReport(categoryBreakdowns: [breakdown(previousAmount: 550)]),
      );

      await pumpReport(tester);

      expect(find.text('Insights del mes'), findsNothing);
      expect(find.byType(InsightCard), findsNothing);
    });

    testWidgets('non-expense breakdown renders chip last, no percentage', (
      tester,
    ) async {
      // Ahorro (no gasto) con monto MAYOR que Food: igual va al final.
      stubReport(
        makeReport(
          categoryBreakdowns: [
            const CategoryBreakdown(
              categoryId: 2,
              categoryName: 'Ahorro',
              amount: 900,
              percentage: 90,
              budgetAmount: 1000,
              isExpense: false,
            ),
            breakdown(),
          ],
        ),
      );

      await pumpReport(tester);

      // Chip solo en la categoría no-gasto.
      expect(find.text('No es gasto'), findsOneWidget);
      // Sin porcentaje: '90.0%' no aparece; el gasto sí conserva el suyo.
      expect(find.text('90.0%'), findsNothing);
      expect(find.text('60.0%'), findsOneWidget);
      // Sin barra de presupuesto para no-gasto (la gasto no tiene budget).
      expect(find.byType(LinearProgressIndicator), findsNothing);
      // Orden: gasto primero, no-gasto al final.
      final names = tester
          .widgetList<CategoryBreakdownTile>(find.byType(CategoryBreakdownTile))
          .map((tile) => tile.breakdown.categoryName);
      expect(names, ['Food', 'Ahorro']);
    });

    testWidgets('ReportContent forwards onInsightTap to InsightCard tap', (
      tester,
    ) async {
      const insight = Insight(
        categoryId: 1,
        categoryName: 'Food',
        currentAmount: 600,
        previousAmount: 480,
        changePct: 25,
        isIncrease: true,
      );
      Insight? tapped;

      await tester.pumpWidget(
        wrapTest(
          child: ReportContent(
            report: _testReport,
            insights: const [insight],
            onCategoryTap: (_) {},
            onInsightTap: (value) => tapped = value,
          ),
          overrides: defaultOverrides(),
          theme: theme,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(InsightCard), findsOneWidget);
      await tester.ensureVisible(find.byType(InsightCard));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InsightCard));
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped, insight);
    });

    testWidgets('tapping an insight opens the comparison sheet', (
      tester,
    ) async {
      stubReport(
        makeReport(categoryBreakdowns: [breakdown(previousAmount: 480)]),
      );

      await tester.pumpWidget(
        wrapTest(
          child: const ReportView(),
          overrides: [
            ...defaultOverrides(),
            expenseControllerProvider.overrideWithValue(
              const AsyncData(<Expense>[]),
            ),
          ],
          theme: theme,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(InsightCard), findsOneWidget);
      await tester.ensureVisible(find.byType(InsightCard));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InsightCard));
      await tester.pumpAndSettle();

      // Sheet comparativa: sección 'Mes anterior' sin gastos (fixture vacía).
      expect(find.text('Mes anterior'), findsOneWidget);
      expect(find.text('Sin gastos el mes anterior'), findsOneWidget);
    });
  });
}
