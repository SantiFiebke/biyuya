import 'dart:async';

import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/domain/repositories/category_repository_base.dart';
import 'package:biyuya/src/features/reports/data/repositories/report_repository_impl.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/report_controller.dart';
import 'package:biyuya/src/features/reports/provider/report_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../helpers/test_helpers.dart';

class MockReportRepository extends Mock implements ReportRepositoryImpl {}

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockCategoryRepository extends Mock implements CategoryRepositoryBase {}

/// Minimal fake of the PostgREST chain used by [ReportRepositoryImpl].
/// ponytail: only `select`/`eq`/`gte`/`lte` are exercised; everything else
/// returns itself so the chain type-checks.
class _FakeQueryBuilder implements supabase.SupabaseQueryBuilder {
  _FakeQueryBuilder(this.rows);

  final List<Map<String, dynamic>> rows;

  @override
  dynamic noSuchMethod(Invocation invocation) => _FakeFilterBuilder(rows);
}

class _FakeFilterBuilder
    implements supabase.PostgrestFilterBuilder<supabase.PostgrestList> {
  _FakeFilterBuilder(this.rows);

  final List<Map<String, dynamic>> rows;

  @override
  dynamic noSuchMethod(Invocation invocation) => this;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(supabase.PostgrestList) onValue, {
    Function? onError,
  }) => Future<supabase.PostgrestList>.value(
    rows,
  ).then(onValue, onError: onError);
}

Map<String, dynamic> _expenseRow({
  int id = 1,
  double amount = 100,
  int categoryId = 1,
}) => {
  'id': id,
  'amount': amount,
  'date': '2025-07-15T00:00:00.000',
  'household_id': 1,
  'category_id': categoryId,
  'created_at': '2025-07-15T00:00:00.000',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReportRepository mockRepo;
  late ProviderContainer container;
  late int currentMonth;
  late int currentYear;

  setUp(() {
    mockRepo = MockReportRepository();
    currentMonth = DateTime.now().month;
    currentYear = DateTime.now().year;

    when(
      () => mockRepo.getMonthlyReport(
        householdId: 1,
        year: any(named: 'year'),
        month: any(named: 'month'),
      ),
    ).thenAnswer(
      (_) async => Success(makeReport(year: currentYear, month: currentMonth)),
    );

    container = ProviderContainer(
      overrides: [
        reportRepositoryProvider.overrideWithValue(mockRepo),
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
    test('build returns null data initially', () {
      final state = container.read(reportControllerProvider);
      // Build seeds a ReportState for the current month; report data loads
      // asynchronously and is still null at this point.
      expect(state.value!.report, isNull);
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
  });

  group('ReportController budgetAmount propagation', () {
    late MockSupabaseClient mockClient;
    late MockCategoryRepository mockCategoryRepo;
    late ProviderContainer budgetContainer;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockCategoryRepo = MockCategoryRepository();

      when(
        () => mockClient.from(any()),
      ).thenAnswer((_) => _FakeQueryBuilder([_expenseRow()]));

      budgetContainer = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWith(
            (ref) => ReportRepositoryImpl(mockClient, mockCategoryRepo),
          ),
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
