import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/reports/data/repositories/report_repository_impl.dart';
import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/domain/entities/savings_report.dart';
import 'package:biyuya/src/features/reports/domain/entities/weekly_report.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockReportRepository extends Mock implements ReportRepositoryImpl {
  /// Stubs the secondary report endpoints with a [ReportFailure] by default.
  ///
  /// `ReportView` mounts `WeeklyReportSection`/`SavingsReportSection`, whose
  /// controllers call these repositories. Returning an error makes those
  /// sections shrink, so view tests only assert on the monthly report. Tests
  /// needing real data re-stub the method (last stub wins in mocktail).
  MockReportRepository() {
    when(
      () => getWeeklyReport(
        householdId: any(named: 'householdId'),
        weekStart: any(named: 'weekStart'),
        categories: any(named: 'categories'),
      ),
    ).thenAnswer((_) async => const Error(ReportFailure('unavailable')));

    when(
      () => getSavingsReport(
        householdId: any(named: 'householdId'),
        year: any(named: 'year'),
        month: any(named: 'month'),
      ),
    ).thenAnswer((_) async => const Error(ReportFailure('unavailable')));
  }
}

// ---------------------------------------------------------------------------
// Fake AuthSessionController
// ---------------------------------------------------------------------------

class FakeAuthSessionController extends AuthSessionController {
  @override
  FutureOr<UserProfile?> build() {
    return const UserProfile(
      id: 'test-user-id',
      name: 'Test',
      lastName: 'User',
      householdId: '1',
    );
  }
}

/// Session without household → report controllers keep AsyncData(null).
class FakeNoHouseholdAuthSession extends AuthSessionController {
  @override
  FutureOr<UserProfile?> build() {
    return const UserProfile(
      id: 'test-user-id',
      name: 'Test',
      lastName: 'User',
    );
  }
}

// ---------------------------------------------------------------------------
// Async test helpers
// ---------------------------------------------------------------------------

/// Yield to the event loop twice so provider updates settle.
Future<void> waitForLoad() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

// ---------------------------------------------------------------------------
// Factory functions
// ---------------------------------------------------------------------------

Category makeCategory({
  int id = 1,
  String name = 'Test',
  int householdId = 1,
  double? budgetAmount,
  bool isExpense = true,
}) {
  return Category(
    id: id,
    name: name,
    householdId: householdId,
    createdAt: DateTime(2025),
    budgetAmount: budgetAmount,
    isExpense: isExpense,
  );
}

Expense makeExpense({
  int id = 1,
  double amount = 100.0,
  String? description = 'Test expense',
  int householdId = 1,
  int categoryId = 1,
  DateTime? date,
  ExpenseSyncStatus syncStatus = ExpenseSyncStatus.synced,
}) {
  return Expense(
    id: id,
    amount: amount,
    date: date ?? DateTime(2025, 7),
    description: description,
    householdId: householdId,
    categoryId: categoryId,
    createdAt: DateTime(2025, 7),
    syncStatus: syncStatus,
  );
}

MonthlyReport makeReport({
  double total = 1000,
  double previousTotal = 800,
  double variation = 25.0,
  int year = 2025,
  int month = 7,
  List<CategoryBreakdown> categoryBreakdowns = const <CategoryBreakdown>[],
}) {
  return MonthlyReport(
    total: total,
    previousTotal: previousTotal,
    variation: variation,
    categoryBreakdowns: categoryBreakdowns,
    year: year,
    month: month,
  );
}

WeeklyReport makeWeeklyReport({
  DateTime? weekStart,
  DateTime? weekEnd,
  double total = 1000,
  double previousWeekTotal = 800,
  double variation = 25,
  int year = 2026,
  int week = 36,
}) {
  final start = weekStart ?? DateTime(2026, 9, 7);
  return WeeklyReport(
    weekStart: start,
    weekEnd: weekEnd ?? start.add(const Duration(days: 7)),
    total: total,
    previousWeekTotal: previousWeekTotal,
    variation: variation,
    breakdowns: const [],
    year: year,
    week: week,
  );
}

SavingsReport makeSavingsReport({
  int year = 2026,
  int month = 9,
  double totalSaved = 100,
  double goalAmount = 600,
  double progressPct = 16.67,
}) {
  return SavingsReport(
    year: year,
    month: month,
    totalSaved: totalSaved,
    goalAmount: goalAmount,
    progressPct: progressPct,
    entries: const [],
  );
}

// ---------------------------------------------------------------------------
// Widget wrapper
// ---------------------------------------------------------------------------

Widget wrapTest({
  required Widget child,
  List<Override> overrides = const <Override>[],
  ThemeData? theme,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: theme,
      localizationsDelegates: const [
        ...GlobalCupertinoLocalizations.delegates,
        ...GlobalMaterialLocalizations.delegates,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'AR')],
      home: Scaffold(body: child),
    ),
  );
}
