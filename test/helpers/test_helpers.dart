import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/reports/data/repositories/report_repository_impl.dart';
import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockReportRepository extends Mock implements ReportRepositoryImpl {}

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

Category makeCategory({int id = 1, String name = 'Test', int householdId = 1}) {
  return Category(
    id: id,
    name: name,
    householdId: householdId,
    createdAt: DateTime(2025),
  );
}

Expense makeExpense({
  int id = 1,
  double amount = 100.0,
  String? description = 'Test expense',
  int householdId = 1,
  int categoryId = 1,
  DateTime? date,
}) {
  return Expense(
    id: id,
    amount: amount,
    date: date ?? DateTime(2025, 7),
    description: description,
    householdId: householdId,
    categoryId: categoryId,
    createdAt: DateTime(2025, 7),
  );
}

MonthlyReport makeReport({
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
    categoryBreakdowns: const <CategoryBreakdown>[],
    year: year,
    month: month,
  );
}

// ---------------------------------------------------------------------------
// Widget wrapper
// ---------------------------------------------------------------------------

Widget wrapTest({
  required Widget child,
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
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
