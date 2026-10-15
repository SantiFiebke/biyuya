import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/provider/categories_provider.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/weekly_report_controller.dart';
import 'package:biyuya/src/features/reports/provider/report_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReportRepository mockRepo;
  late ProviderContainer container;
  late List<DateTime> weekCalls;

  DateTime mondayOfCurrentWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: now.weekday - 1));
  }

  setUp(() {
    mockRepo = MockReportRepository();
    weekCalls = <DateTime>[];

    when(
      () => mockRepo.getWeeklyReport(
        householdId: 1,
        weekStart: any(named: 'weekStart'),
        categories: any(named: 'categories'),
      ),
    ).thenAnswer((invocation) async {
      weekCalls.add(invocation.namedArguments[#weekStart] as DateTime);
      return Success(makeWeeklyReport());
    });

    container = ProviderContainer(
      overrides: [
        reportRepositoryProvider.overrideWithValue(mockRepo),
        categoriesProvider.overrideWith((ref) async => const <Category>[]),
        authSessionControllerProvider.overrideWith(
          FakeAuthSessionController.new,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('WeeklyReportController', () {
    test('build seeds current week with null report initially', () async {
      final state = container.read(weeklyReportControllerProvider);
      expect(state.value!.report, isNull);
      expect(state.value!.weekStart, mondayOfCurrentWeek());
      // Drain the unawaited _loadReport microtask before teardown.
      await waitForLoad();
    });

    test('build auto-loads weekly report via microtask', () async {
      container.read(weeklyReportControllerProvider);
      await waitForLoad();

      final state = container.read(weeklyReportControllerProvider);
      expect(state.value!.report, isNotNull);
      expect(state.value!.report!.total, 1000);
      expect(state.value!.weekStart, mondayOfCurrentWeek());
    });

    test('build sets AsyncError on load failure', () async {
      when(
        () => mockRepo.getWeeklyReport(
          householdId: 1,
          weekStart: any(named: 'weekStart'),
          categories: any(named: 'categories'),
        ),
      ).thenAnswer((_) async => const Error(ReportFailure('db error')));

      container.read(weeklyReportControllerProvider);
      await waitForLoad();

      expect(container.read(weeklyReportControllerProvider).hasError, isTrue);
    });

    test('previousWeek subtracts 7 days and reloads', () async {
      container.read(weeklyReportControllerProvider);
      await waitForLoad();

      final notifier = container.read(weeklyReportControllerProvider.notifier);
      final before = container
          .read(weeklyReportControllerProvider)
          .value!
          .weekStart;

      await notifier.previousWeek();

      final state = container.read(weeklyReportControllerProvider);
      expect(state.value!.weekStart, before.subtract(const Duration(days: 7)));
      expect(state.value!.report, isNotNull);
    });

    test('nextWeek adds 7 days when not at current week', () async {
      container.read(weeklyReportControllerProvider);
      await waitForLoad();

      final notifier = container.read(weeklyReportControllerProvider.notifier);
      await notifier.previousWeek();
      final before = container
          .read(weeklyReportControllerProvider)
          .value!
          .weekStart;

      await notifier.nextWeek();

      final state = container.read(weeklyReportControllerProvider);
      expect(state.value!.weekStart, before.add(const Duration(days: 7)));
      expect(state.value!.weekStart, mondayOfCurrentWeek());
    });

    test('nextWeek does not go beyond current week', () async {
      container.read(weeklyReportControllerProvider);
      await waitForLoad();

      final notifier = container.read(weeklyReportControllerProvider.notifier);
      await notifier.nextWeek();

      expect(
        container.read(weeklyReportControllerProvider).value!.weekStart,
        mondayOfCurrentWeek(),
      );
    });

    test('canGoNext is false at current week and true after previousWeek', () async {
      container.read(weeklyReportControllerProvider);
      await waitForLoad();

      final notifier = container.read(weeklyReportControllerProvider.notifier);
      expect(notifier.canGoNext, isFalse);

      await notifier.previousWeek();
      expect(notifier.canGoNext, isTrue);
    });

    test('refresh reloads the selected week without resetting to now()', () async {
      container.read(weeklyReportControllerProvider);
      await waitForLoad();

      final notifier = container.read(weeklyReportControllerProvider.notifier);
      await notifier.previousWeek();
      final selected = container
          .read(weeklyReportControllerProvider)
          .value!
          .weekStart;

      weekCalls.clear();
      await notifier.refresh();

      expect(weekCalls, [selected]);
      final state = container.read(weeklyReportControllerProvider);
      expect(state.value!.weekStart, selected);
      expect(state.value!.report, isNotNull);
    });

    test('householdId null keeps state with null report', () async {
      final noHousehold = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWithValue(mockRepo),
          categoriesProvider.overrideWith((ref) async => const <Category>[]),
          authSessionControllerProvider.overrideWith(
            FakeNoHouseholdAuthSession.new,
          ),
        ],
      );
      addTearDown(noHousehold.dispose);

      noHousehold.read(weeklyReportControllerProvider);
      await waitForLoad();

      final state = noHousehold.read(weeklyReportControllerProvider);
      expect(state.value!.report, isNull);
      expect(state.value!.weekStart, mondayOfCurrentWeek());
      expect(weekCalls, isEmpty);
    });
  });
}
