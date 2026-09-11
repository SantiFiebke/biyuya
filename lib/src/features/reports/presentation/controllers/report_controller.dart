import 'dart:async';

import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/provider/report_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_controller.g.dart';

@Riverpod(keepAlive: true)
class ReportController extends _$ReportController {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;

  @override
  AsyncValue<MonthlyReport?> build() {
    unawaited(Future.microtask(_loadReport));
    return const AsyncData(null);
  }

  Future<void> _loadReport() async {
    final session = ref.read(authSessionControllerProvider);
    final householdId = session.value?.householdId;

    if (householdId == null || householdId.isEmpty) {
      state = const AsyncData(null);
      return;
    }

    state = const AsyncLoading();
    final repository = ref.read(reportRepositoryProvider);
    final result = await repository.getMonthlyReport(
      householdId: int.parse(householdId),
      year: _selectedYear,
      month: _selectedMonth,
    );
    result.when(
      (report) => state = AsyncData(report),
      (failure) => state = AsyncError(failure, StackTrace.current),
    );
  }

  Future<void> loadReportForMonth({
    required int year,
    required int month,
  }) async {
    _selectedYear = year;
    _selectedMonth = month;
    await _loadReport();
  }

  Future<void> previousMonth() async {
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear--;
    } else {
      _selectedMonth--;
    }
    await _loadReport();
  }

  Future<void> nextMonth() async {
    final now = DateTime.now();
    // Don't go beyond current month
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      return;
    }

    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear++;
    } else {
      _selectedMonth++;
    }
    await _loadReport();
  }

  bool get canGoNext {
    final now = DateTime.now();
    return !(_selectedYear == now.year && _selectedMonth == now.month);
  }
}
