import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/savings_report_controller.dart';
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
  late List<String> savingsCalls;

  setUp(() {
    mockRepo = MockReportRepository();
    savingsCalls = <String>[];

    when(
      () => mockRepo.getSavingsReport(
        householdId: 1,
        year: any(named: 'year'),
        month: any(named: 'month'),
      ),
    ).thenAnswer((invocation) async {
      savingsCalls.add(
        '${invocation.namedArguments[#year]}-'
        '${invocation.namedArguments[#month]}',
      );
      return Success(makeSavingsReport());
    });

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

  group('SavingsReportController', () {
    test('build seeds current month with null report initially', () async {
      final now = DateTime.now();
      final state = container.read(savingsReportControllerProvider);
      expect(state.value!.report, isNull);
      expect(state.value!.year, now.year);
      expect(state.value!.month, now.month);
      // Drain the unawaited _loadReport microtask before teardown.
      await waitForLoad();
    });

    test('build auto-loads savings report via microtask', () async {
      container.read(savingsReportControllerProvider);
      await waitForLoad();

      final state = container.read(savingsReportControllerProvider);
      expect(state.value!.report, isNotNull);
      expect(state.value!.report!.totalSaved, 100);
    });

    test('build sets AsyncError on load failure', () async {
      when(
        () => mockRepo.getSavingsReport(
          householdId: 1,
          year: any(named: 'year'),
          month: any(named: 'month'),
        ),
      ).thenAnswer((_) async => const Error(ReportFailure('db error')));

      container.read(savingsReportControllerProvider);
      await waitForLoad();

      expect(container.read(savingsReportControllerProvider).hasError, isTrue);
    });

    test('refresh reloads the selected month without resetting to now()', () async {
      container.read(savingsReportControllerProvider);
      await waitForLoad();

      final now = DateTime.now();
      final notifier = container.read(savingsReportControllerProvider.notifier);

      savingsCalls.clear();
      await notifier.refresh();

      expect(savingsCalls, ['${now.year}-${now.month}']);
      final state = container.read(savingsReportControllerProvider);
      expect(state.value!.year, now.year);
      expect(state.value!.month, now.month);
      expect(state.value!.report, isNotNull);
    });

    test('householdId null keeps state with null report', () async {
      final noHousehold = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWithValue(mockRepo),
          authSessionControllerProvider.overrideWith(
            FakeNoHouseholdAuthSession.new,
          ),
        ],
      );
      addTearDown(noHousehold.dispose);

      noHousehold.read(savingsReportControllerProvider);
      await waitForLoad();

      final state = noHousehold.read(savingsReportControllerProvider);
      expect(state.value!.report, isNull);
      expect(savingsCalls, isEmpty);
    });
  });
}
