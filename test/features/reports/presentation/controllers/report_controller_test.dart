import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/reports/data/repositories/report_repository_impl.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/report_controller.dart';
import 'package:biyuya/src/features/reports/provider/report_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';

class MockReportRepository extends Mock implements ReportRepositoryImpl {}

class _FakeAuthSessionController extends AuthSessionController {
  @override
  FutureOr<UserProfile?> build() => const UserProfile(
    id: 'test-user-id',
    name: 'Test',
    lastName: 'User',
    householdId: '1',
  );
}

MonthlyReport _makeReport({
  double total = 1000,
  double previousTotal = 800,
  double variation = 25.0,
  int year = 2025,
  int month = 7,
}) {
  return MonthlyReport(
    total: total,
    previousTotal: previousTotal,
    variation: variation,
    categoryBreakdowns: const [],
    year: year,
    month: month,
  );
}

/// Wait for build()'s Future.microtask auto-load to settle.
Future<void> _waitForLoad() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
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
      (_) async => Success(_makeReport(year: currentYear, month: currentMonth)),
    );

    container = ProviderContainer(
      overrides: [
        reportRepositoryProvider.overrideWithValue(mockRepo),
        authSessionControllerProvider.overrideWith(
          _FakeAuthSessionController.new,
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
      expect(state.value, isNull);
    });

    test('build auto-loads report via microtask', () async {
      container.read(reportControllerProvider);
      await _waitForLoad();

      final state = container.read(reportControllerProvider);
      expect(state.value, isNotNull);
      expect(state.value!.total, 1000);
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
      await _waitForLoad();

      expect(container.read(reportControllerProvider).hasError, isTrue);
    });

    test('previousMonth decrements month correctly', () async {
      container.read(reportControllerProvider);
      await _waitForLoad();

      final notifier = container.read(reportControllerProvider.notifier);
      expect(notifier.selectedMonth, currentMonth);

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
            Success(_makeReport(month: expectedMonth, year: expectedYear)),
      );

      await notifier.previousMonth();
      expect(notifier.selectedMonth, expectedMonth);
      expect(notifier.selectedYear, expectedYear);
    });

    test('previousMonth wraps from January to December', () async {
      container.read(reportControllerProvider);
      await _waitForLoad();

      final notifier = container.read(reportControllerProvider.notifier);

      // Set to January of current year
      when(
        () => mockRepo.getMonthlyReport(
          householdId: 1,
          year: currentYear,
          month: 1,
        ),
      ).thenAnswer(
        (_) async => Success(_makeReport(month: 1, year: currentYear)),
      );

      await notifier.loadReportForMonth(year: currentYear, month: 1);
      expect(notifier.selectedMonth, 1);
      expect(notifier.selectedYear, currentYear);

      // Now go previous → should wrap to December of previous year
      when(
        () => mockRepo.getMonthlyReport(
          householdId: 1,
          year: currentYear - 1,
          month: 12,
        ),
      ).thenAnswer(
        (_) async => Success(_makeReport(month: 12, year: currentYear - 1)),
      );

      await notifier.previousMonth();
      expect(notifier.selectedMonth, 12);
      expect(notifier.selectedYear, currentYear - 1);
    });

    test('nextMonth increments month correctly', () async {
      container.read(reportControllerProvider);
      await _waitForLoad();

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
        (_) async => Success(_makeReport(month: targetMonth, year: targetYear)),
      );

      await notifier.loadReportForMonth(year: targetYear, month: targetMonth);
      expect(notifier.selectedMonth, targetMonth);

      // Next should go to current month
      when(
        () => mockRepo.getMonthlyReport(
          householdId: 1,
          year: currentYear,
          month: currentMonth,
        ),
      ).thenAnswer(
        (_) async =>
            Success(_makeReport(month: currentMonth, year: currentYear)),
      );

      await notifier.nextMonth();
      expect(notifier.selectedMonth, currentMonth);
    });

    test('nextMonth does not go beyond current month', () async {
      container.read(reportControllerProvider);
      await _waitForLoad();

      final notifier = container.read(reportControllerProvider.notifier);

      // Already at current month (default)
      expect(notifier.selectedMonth, currentMonth);

      await notifier.nextMonth();
      expect(notifier.selectedMonth, currentMonth);
    });

    test('canGoNext returns false when at current month', () async {
      container.read(reportControllerProvider);
      await _waitForLoad();

      final notifier = container.read(reportControllerProvider.notifier);
      expect(notifier.canGoNext, isFalse);
    });

    test('canGoNext returns true when not at current month', () async {
      when(
        () => mockRepo.getMonthlyReport(householdId: 1, year: 2024, month: 1),
      ).thenAnswer((_) async => Success(_makeReport(month: 1, year: 2024)));

      container.read(reportControllerProvider);
      await _waitForLoad();

      final notifier = container.read(reportControllerProvider.notifier);
      await notifier.loadReportForMonth(year: 2024, month: 1);

      expect(notifier.canGoNext, isTrue);
    });

    test('loadReportForMonth updates selectedYear and selectedMonth', () async {
      when(
        () => mockRepo.getMonthlyReport(householdId: 1, year: 2024, month: 3),
      ).thenAnswer((_) async => Success(_makeReport(month: 3, year: 2024)));

      container.read(reportControllerProvider);
      await _waitForLoad();

      final notifier = container.read(reportControllerProvider.notifier);
      await notifier.loadReportForMonth(year: 2024, month: 3);

      expect(notifier.selectedYear, 2024);
      expect(notifier.selectedMonth, 3);

      final state = container.read(reportControllerProvider);
      expect(state.value!.month, 3);
      expect(state.value!.year, 2024);
    });
  });
}
