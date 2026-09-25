import 'dart:async';

import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:biyuya/src/features/reports/presentation/views/report_view.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/insights_section.dart';
import 'package:biyuya/src/features/reports/provider/report_repository_provider.dart';
import 'package:biyuya/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

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
    );
  }

  setUp(() {
    mockRepo = MockReportRepository();
    when(
      () => mockRepo.getMonthlyReport(
        householdId: any(named: 'householdId'),
        year: any(named: 'year'),
        month: any(named: 'month'),
      ),
    ).thenAnswer((_) async => const Success(_testReport));
  });

  List<Override> defaultOverrides() => [
    reportRepositoryProvider.overrideWithValue(mockRepo),
    authSessionControllerProvider.overrideWith(FakeAuthSessionController.new),
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
      final completer = Completer<Success<MonthlyReport, ReportFailure>>();
      final stuckRepo = MockReportRepository();
      when(
        () => stuckRepo.getMonthlyReport(
          householdId: any(named: 'householdId'),
          year: any(named: 'year'),
          month: any(named: 'month'),
        ),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        wrapTest(
          child: const ReportView(),
          overrides: [
            reportRepositoryProvider.overrideWithValue(stuckRepo),
            authSessionControllerProvider.overrideWith(
              FakeAuthSessionController.new,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(ReportSkeleton), findsOneWidget);

      // Complete the future to avoid pending timer on teardown
      completer.complete(
        const Success(
          MonthlyReport(
            total: 0,
            previousTotal: 0,
            variation: 0,
            categoryBreakdowns: [],
            year: 2025,
            month: 7,
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('shows error text on failure', (tester) async {
      when(
        () => mockRepo.getMonthlyReport(
          householdId: any(named: 'householdId'),
          year: any(named: 'year'),
          month: any(named: 'month'),
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

    testWidgets('shows progress bar when breakdown has budget', (tester) async {
      stubReport(
        makeReport(categoryBreakdowns: [breakdown(budgetAmount: 500)]),
      );

      await pumpReport(tester);

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
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
        find.byType(LinearProgressIndicator),
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
        find.byType(LinearProgressIndicator),
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
  });
}
