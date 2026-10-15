import 'dart:async';

import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/domain/repositories/category_repository_base.dart';
import 'package:biyuya/src/features/categories/provider/category_repository_provider.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:biyuya/src/features/reports/data/repositories/report_repository_impl.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/report_controller.dart';
import 'package:biyuya/src/features/reports/provider/report_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../helpers/test_helpers.dart';

class MockReportRepository extends Mock implements ReportRepositoryImpl {}

class MockExpenseRepository extends Mock implements ExpenseRepositoryBase {}

class MockCategoryRepository extends Mock implements CategoryRepositoryBase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReportRepository mockRepo;
  late MockCategoryRepository categoryRepo;
  late ProviderContainer container;
  late int currentMonth;
  late int currentYear;

  /// Every `getMonthlyReport` call as `'year-month'`, in order — used to
  /// assert WHICH month the controller fetched.
  late List<String> reportCalls;

  setUp(() {
    mockRepo = MockReportRepository();
    categoryRepo = MockCategoryRepository();
    when(
      () => categoryRepo.getCategories(householdId: any(named: 'householdId')),
    ).thenAnswer((_) async => const Success(<Category>[]));
    currentMonth = DateTime.now().month;
    currentYear = DateTime.now().year;
    reportCalls = <String>[];

    when(
      () => mockRepo.getMonthlyReport(
        householdId: 1,
        year: any(named: 'year'),
        month: any(named: 'month'),
        categories: any(named: 'categories'),
      ),
    ).thenAnswer((invocation) async {
      reportCalls.add(
        '${invocation.namedArguments[#year]}-${invocation.namedArguments[#month]}',
      );
      return Success(makeReport(year: currentYear, month: currentMonth));
    });

    container = ProviderContainer(
      overrides: [
        reportRepositoryProvider.overrideWithValue(mockRepo),
        // ReportController now resolves categories via categoriesProvider,
        // which reads categoryRepositoryProvider. Keep Supabase out.
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        authSessionControllerProvider.overrideWith(
          FakeAuthSessionController.new,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ReportController', () {
    test('build returns null data initially', () async {
      final state = container.read(reportControllerProvider);
      // Build seeds a ReportState for the current month; report data loads
      // asynchronously and is still null at this point.
      expect(state.value!.report, isNull);
      // Drain the unawaited _loadReport microtask before teardown.
      await waitForLoad();
    });

    test('build auto-loads report via microtask', () async {
      container.read(reportControllerProvider);
      await waitForLoad();

      final state = container.read(reportControllerProvider);
      expect(state.value, isNotNull);
      expect(state.value!.report!.total, 1000);
    });

    test('build sets AsyncError on load failure', () async {
      when(
        () => mockRepo.getMonthlyReport(
          householdId: 1,
          year: any(named: 'year'),
          month: any(named: 'month'),
          categories: any(named: 'categories'),
        ),
      ).thenAnswer((_) async => const Error(ReportFailure('db error')));

      container.read(reportControllerProvider);
      await waitForLoad();

      expect(container.read(reportControllerProvider).hasError, isTrue);
    });

    test('previousMonth decrements month correctly', () async {
      container.read(reportControllerProvider);
      await waitForLoad();

      final notifier = container.read(reportControllerProvider.notifier);
      expect(
        container.read(reportControllerProvider).value!.month,
        currentMonth,
      );

      final expectedMonth = currentMonth == 1 ? 12 : currentMonth - 1;
      final expectedYear = currentMonth == 1 ? currentYear - 1 : currentYear;

      when(
        () => mockRepo.getMonthlyReport(
          householdId: 1,
          year: expectedYear,
          month: expectedMonth,
          categories: any(named: 'categories'),
        ),
      ).thenAnswer(
        (_) async =>
            Success(makeReport(month: expectedMonth, year: expectedYear)),
      );

      await notifier.previousMonth();
      expect(
        container.read(reportControllerProvider).value!.month,
        expectedMonth,
      );
      expect(
        container.read(reportControllerProvider).value!.year,
        expectedYear,
      );
    });

    test('previousMonth wraps from January to December', () async {
      container.read(reportControllerProvider);
      await waitForLoad();

      final notifier = container.read(reportControllerProvider.notifier);

      // Walk back to January with the supported API (loadReportForMonth was
      // removed; previousMonth from the build-seeded current month reaches
      // January without crossing a year boundary).
      while (container.read(reportControllerProvider).value!.month != 1) {
        await notifier.previousMonth();
      }
      expect(container.read(reportControllerProvider).value!.month, 1);
      expect(container.read(reportControllerProvider).value!.year, currentYear);

      // Now go previous → should wrap to December of previous year
      when(
        () => mockRepo.getMonthlyReport(
          householdId: 1,
          year: currentYear - 1,
          month: 12,
          categories: any(named: 'categories'),
        ),
      ).thenAnswer(
        (_) async => Success(makeReport(month: 12, year: currentYear - 1)),
      );

      await notifier.previousMonth();
      expect(container.read(reportControllerProvider).value!.month, 12);
      expect(
        container.read(reportControllerProvider).value!.year,
        currentYear - 1,
      );
    });

    test('nextMonth increments month correctly', () async {
      container.read(reportControllerProvider);
      await waitForLoad();

      final notifier = container.read(reportControllerProvider.notifier);

      // Move to one month before current
      final targetMonth = currentMonth == 1 ? 12 : currentMonth - 1;
      final targetYear = currentMonth == 1 ? currentYear - 1 : currentYear;

      when(
        () => mockRepo.getMonthlyReport(
          householdId: 1,
          year: targetYear,
          month: targetMonth,
          categories: any(named: 'categories'),
        ),
      ).thenAnswer(
        (_) async => Success(makeReport(month: targetMonth, year: targetYear)),
      );

      // previousMonth from the build-seeded current month lands exactly on
      // the target (including the January → December wrap).
      await notifier.previousMonth();
      expect(
        container.read(reportControllerProvider).value!.month,
        targetMonth,
      );

      // Next should go to current month
      when(
        () => mockRepo.getMonthlyReport(
          householdId: 1,
          year: currentYear,
          month: currentMonth,
          categories: any(named: 'categories'),
        ),
      ).thenAnswer(
        (_) async =>
            Success(makeReport(month: currentMonth, year: currentYear)),
      );

      await notifier.nextMonth();
      expect(
        container.read(reportControllerProvider).value!.month,
        currentMonth,
      );
    });

    test('nextMonth does not go beyond current month', () async {
      container.read(reportControllerProvider);
      await waitForLoad();

      final notifier = container.read(reportControllerProvider.notifier);

      // Already at current month (default)
      expect(
        container.read(reportControllerProvider).value!.month,
        currentMonth,
      );

      await notifier.nextMonth();
      expect(
        container.read(reportControllerProvider).value!.month,
        currentMonth,
      );
    });

    test('canGoNext returns false when at current month', () async {
      container.read(reportControllerProvider);
      await waitForLoad();

      final notifier = container.read(reportControllerProvider.notifier);
      expect(notifier.canGoNext, isFalse);
    });

    test('canGoNext returns true when not at current month', () async {
      container.read(reportControllerProvider);
      await waitForLoad();

      final notifier = container.read(reportControllerProvider.notifier);
      // One step back from the build-seeded current month → not current.
      await notifier.previousMonth();

      expect(notifier.canGoNext, isTrue);
    });

    test(
      'refresh reloads the selected month without resetting to now()',
      () async {
        // Regression: refresh() must re-fetch the month currently selected in
        // state instead of rebuilding with DateTime.now().
        container.read(reportControllerProvider);
        await waitForLoad();

        ReportState stateOf() =>
            container.read(reportControllerProvider).value!;

        final notifier = container.read(reportControllerProvider.notifier);
        // Walk back from the build-seeded current month to August 2026.
        var guard = 0;
        while (!(stateOf().year == 2026 && stateOf().month == 8)) {
          await notifier.previousMonth();
          expect(++guard, lessThan(24), reason: 'never reached Aug 2026');
        }
        expect(stateOf().month, 8);

        reportCalls.clear();
        await notifier.refresh();

        // Repo hit for the selected month (2026-08), not for now().
        expect(reportCalls, contains('2026-8'));
        final state = stateOf();
        expect(state.year, 2026);
        expect(state.month, 8);
        expect(state.report, isNotNull);
      },
    );

    test('refresh during in-flight load retains value and still applies', () async {
      // Regression (TEST-006b): a concurrent/duplicate load must NOT leave
      // state stuck in AsyncLoading. copyWithPrevious retains the previous
      // value during the reload, so refresh() is no longer a no-op — it starts
      // a new fetch and the pending response still applies.
      final completer = Completer<Result<MonthlyReport, ReportFailure>>();
      when(
        () => mockRepo.getMonthlyReport(
          householdId: 1,
          year: any(named: 'year'),
          month: any(named: 'month'),
          categories: any(named: 'categories'),
        ),
      ).thenAnswer((invocation) {
        reportCalls.add(
          '${invocation.namedArguments[#year]}-'
          '${invocation.namedArguments[#month]}',
        );
        return completer.future;
      });

      container.read(reportControllerProvider);
      await waitForLoad();

      // First load reached AsyncLoading but retained the seeded value.
      final loading = container.read(reportControllerProvider);
      expect(loading.isLoading, isTrue);
      expect(loading.value, isNotNull);
      expect(loading.value!.report, isNull);
      expect(reportCalls, hasLength(1));

      // Duplicate load while the fetch is pending: value retained → not a
      // no-op, a second repository call starts.
      unawaited(container.read(reportControllerProvider.notifier).refresh());
      await waitForLoad();
      expect(reportCalls, hasLength(2));

      completer.complete(
        Success(makeReport(year: currentYear, month: currentMonth)),
      );
      await waitForLoad();

      // The pending fetch still applies: AsyncData, not stuck AsyncLoading.
      final state = container.read(reportControllerProvider);
      expect(state, isA<AsyncData<ReportState>>());
      expect(state.isLoading, isFalse);
      expect(state.value!.report, isNotNull);
      expect(state.value!.report!.total, 1000);
      expect(state.value!.year, currentYear);
      expect(state.value!.month, currentMonth);
    });
  });

  group('ReportController budgetAmount propagation', () {
    late MockExpenseRepository mockExpenseRepo;
    late MockCategoryRepository mockCategoryRepo;
    late ProviderContainer budgetContainer;

    setUp(() {
      mockExpenseRepo = MockExpenseRepository();
      mockCategoryRepo = MockCategoryRepository();

      when(
        () => mockExpenseRepo.getExpensesByMonth(
          householdId: any(named: 'householdId'),
          year: any(named: 'year'),
          month: any(named: 'month'),
        ),
      ).thenAnswer((_) async => Success([makeExpense()]));

      budgetContainer = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWith(
            (ref) => ReportRepositoryImpl(mockExpenseRepo),
          ),
          // categoriesProvider resolves categories through the category
          // repository; this is what feeds the real ReportRepositoryImpl.
          categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
          authSessionControllerProvider.overrideWith(
            FakeAuthSessionController.new,
          ),
        ],
      );
    });

    tearDown(() {
      budgetContainer.dispose();
    });

    test('breakdown carries category budgetAmount', () async {
      when(
        () => mockCategoryRepo.getCategories(householdId: 1),
      ).thenAnswer((_) async => Success([makeCategory(budgetAmount: 300)]));

      budgetContainer.read(reportControllerProvider);
      await waitForLoad();

      final state = budgetContainer.read(reportControllerProvider);
      final breakdown = state.value!.report!.categoryBreakdowns.single;
      expect(breakdown.categoryId, 1);
      expect(breakdown.budgetAmount, 300);
    });

    test('breakdown budgetAmount is null when category has none', () async {
      when(
        () => mockCategoryRepo.getCategories(householdId: 1),
      ).thenAnswer((_) async => Success([makeCategory()]));

      budgetContainer.read(reportControllerProvider);
      await waitForLoad();

      final state = budgetContainer.read(reportControllerProvider);
      final breakdown = state.value!.report!.categoryBreakdowns.single;
      expect(breakdown.categoryId, 1);
      expect(breakdown.budgetAmount, isNull);
    });
  });
}
