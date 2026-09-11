import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/reports/data/repositories/report_repository_impl.dart';
import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:biyuya/src/features/reports/presentation/views/report_view.dart';
import 'package:biyuya/src/features/reports/provider/report_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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

/// Returns a fake auth controller that produces a user without a household.
class _FakeNoHouseholdAuthSessionController extends AuthSessionController {
  @override
  FutureOr<UserProfile?> build() =>
      const UserProfile(id: 'test-user-id', name: 'Test', lastName: 'User');
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

const _emptyBreakdownReport = MonthlyReport(
  total: 0,
  previousTotal: 0,
  variation: 0,
  categoryBreakdowns: [],
  year: 2025,
  month: 7,
);

/// Wait for build()'s Future.microtask auto-load to settle.
Future<void> _waitForLoad() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

/// Wraps widget with ProviderScope using real notifier + mocked deps.
/// [mockRepo] controls what the controller loads.
/// [authController] controls auth session (default: user with household).
Widget wrapWithOverrides(
  Widget child, {
  MockReportRepository? mockRepo,
  AuthSessionController Function()? authController,
}) {
  final repo = mockRepo ?? MockReportRepository();
  // Default: return the test report for any month query
  when(
    () => repo.getMonthlyReport(
      householdId: any(named: 'householdId'),
      year: any(named: 'year'),
      month: any(named: 'month'),
    ),
  ).thenAnswer((_) async => const Success(_testReport));

  return ProviderScope(
    overrides: [
      reportRepositoryProvider.overrideWithValue(repo),
      authSessionControllerProvider.overrideWith(
        authController ?? _FakeAuthSessionController.new,
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockReportRepository mockRepo;

  setUp(() {
    mockRepo = MockReportRepository();
  });

  group('ReportView', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(wrapWithOverrides(const ReportView()));
      await _waitForLoad();
      await tester.pumpAndSettle();

      expect(find.text('Reportes'), findsOneWidget);
    });

    testWidgets('renders month selector with month name', (tester) async {
      await tester.pumpWidget(wrapWithOverrides(const ReportView()));
      await _waitForLoad();
      await tester.pumpAndSettle();

      expect(find.text('Julio 2025'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders summary card with total and variation', (
      tester,
    ) async {
      await tester.pumpWidget(wrapWithOverrides(const ReportView()));
      await _waitForLoad();
      await tester.pumpAndSettle();

      expect(find.text('Total del mes'), findsOneWidget);
      expect(find.text(r'$1.000'), findsOneWidget);
      expect(find.text('+25.0% vs mes anterior'), findsOneWidget);
    });

    testWidgets('renders category breakdown list', (tester) async {
      await tester.pumpWidget(wrapWithOverrides(const ReportView()));
      await _waitForLoad();
      await tester.pumpAndSettle();

      expect(find.text('Desglose por categoría'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('60.0%'), findsOneWidget);
      expect(find.text('40.0%'), findsOneWidget);
    });

    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(
        wrapWithOverrides(
          const ReportView(),
          authController: _FakeNoHouseholdAuthSessionController.new,
        ),
      );
      await _waitForLoad();
      await tester.pumpAndSettle();

      expect(find.text('No hay datos para este mes'), findsOneWidget);
    });

    testWidgets('shows empty breakdown message when no expenses', (
      tester,
    ) async {
      when(
        () => mockRepo.getMonthlyReport(
          householdId: any(named: 'householdId'),
          year: any(named: 'year'),
          month: any(named: 'month'),
        ),
      ).thenAnswer((_) async => const Success(_emptyBreakdownReport));

      await tester.pumpWidget(
        wrapWithOverrides(const ReportView(), mockRepo: mockRepo),
      );
      await _waitForLoad();
      await tester.pumpAndSettle();

      expect(find.text('No hay gastos este mes'), findsOneWidget);
    });

    testWidgets('shows error state on failure', (tester) async {
      when(
        () => mockRepo.getMonthlyReport(
          householdId: any(named: 'householdId'),
          year: any(named: 'year'),
          month: any(named: 'month'),
        ),
      ).thenAnswer((_) async => const Error(ReportFailure('fail')));

      await tester.pumpWidget(
        wrapWithOverrides(const ReportView(), mockRepo: mockRepo),
      );
      await _waitForLoad();
      await tester.pumpAndSettle();

      expect(find.text('Error al cargar reporte'), findsOneWidget);
    });

    testWidgets('shows loading skeleton', (tester) async {
      // Never complete the repo call so controller stays in AsyncLoading
      final stuckRepo = MockReportRepository();
      when(
        () => stuckRepo.getMonthlyReport(
          householdId: any(named: 'householdId'),
          year: any(named: 'year'),
          month: any(named: 'month'),
        ),
      ).thenAnswer((_) async {
        // Wait forever — keeps controller in loading state
        await Completer<void>().future;
        return const Success(
          MonthlyReport(
            total: 0,
            previousTotal: 0,
            variation: 0,
            categoryBreakdowns: [],
            year: 0,
            month: 0,
          ),
        );
      });

      await tester.pumpWidget(
        wrapWithOverrides(const ReportView(), mockRepo: stuckRepo),
      );
      // Don't let microtask complete — stay in loading
      await Future<void>.delayed(Duration.zero);
      await tester.pump();

      expect(find.byType(ReportSkeleton), findsOneWidget);
    });

    testWidgets('next button disabled when at current month', (tester) async {
      final now = DateTime.now();
      final currentMonthReport = MonthlyReport(
        total: 500,
        previousTotal: 0,
        variation: 0,
        categoryBreakdowns: const [],
        year: now.year,
        month: now.month,
      );

      when(
        () => mockRepo.getMonthlyReport(
          householdId: any(named: 'householdId'),
          year: any(named: 'year'),
          month: any(named: 'month'),
        ),
      ).thenAnswer((_) async => Success(currentMonthReport));

      await tester.pumpWidget(
        wrapWithOverrides(const ReportView(), mockRepo: mockRepo),
      );
      await _waitForLoad();
      await tester.pumpAndSettle();

      // next button should be disabled (onPressed is null)
      final rightButton = tester.widget<IconButton>(
        find.byIcon(Icons.chevron_right),
      );
      expect(rightButton.onPressed, isNull);
    });
  });
}
