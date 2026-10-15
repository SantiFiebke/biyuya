import 'dart:async';

import 'package:biyuya/src/core/utils/request_guard.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/provider/categories_provider.dart';
import 'package:biyuya/src/features/reports/domain/entities/weekly_report.dart';
import 'package:biyuya/src/features/reports/provider/report_repository_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weekly_report_controller.g.dart';

/// Estado inmutable del reporte semanal: la semana seleccionada vive en el
/// state (fuente única de verdad), no en campos del notifier — así un rebuild
/// (logout/login) la resetea junto con `build()`.
class WeeklyReportState extends Equatable {
  const WeeklyReportState({required this.weekStart, this.report});

  final WeeklyReport? report;
  final DateTime weekStart;

  @override
  List<Object?> get props => [report, weekStart];
}

@Riverpod(keepAlive: true)
class WeeklyReportController extends _$WeeklyReportController
    with RequestGuard {
  @override
  AsyncValue<WeeklyReportState> build() {
    invalidateRequests();
    unawaited(Future.microtask(_loadReport));
    return AsyncData(WeeklyReportState(weekStart: _mondayOfCurrentWeek()));
  }

  /// Lunes de la semana actual (DateTime.weekday: 1 = lunes).
  DateTime _mondayOfCurrentWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: now.weekday - 1));
  }

  Future<void> _loadReport() async {
    // Capturado antes del AsyncLoading: fija qué semana dispara esta carga.
    final selected = state.value;
    if (selected == null) {
      // Sin semana seleccionada (carga en vuelo o estado de error): no-op. NO
      // invalidamos acá: eso descartaría la respuesta en vuelo y dejaría el
      // estado atascado en AsyncLoading.
      return;
    }
    final householdId = ref
        .read(authSessionControllerProvider)
        .value
        ?.householdIdValue;
    if (householdId == null) {
      state = AsyncData(WeeklyReportState(weekStart: selected.weekStart));
      return;
    }

    // Retiene el reporte anterior durante la recarga (sin salto de layout).
    // ignore: invalid_use_of_internal_member
    state = const AsyncLoading<WeeklyReportState>().copyWithPrevious(state);
    final result = await runLatest(() async {
      List<Category> categories;
      try {
        categories = await ref.read(categoriesProvider.future);
      } on Object catch (_) {
        categories = const <Category>[];
      }
      return await ref
          .read(reportRepositoryProvider)
          .getWeeklyReport(
            householdId: householdId,
            weekStart: selected.weekStart,
            categories: categories,
          );
    });
    if (result == null) {
      return; // obsoleta: arrancó otra carga
    }
    if (!ref.mounted) {
      return;
    }
    result.when(
      (report) => state = AsyncData(
        WeeklyReportState(report: report, weekStart: selected.weekStart),
      ),
      (failure) => state = AsyncError(failure, StackTrace.current),
    );
  }

  /// Recarga el reporte de la semana seleccionada sin perder la selección.
  /// A diferencia de `invalidate`, no re-ejecuta `build()` (que resetearía la
  /// semana a la actual), así la semana elegida se conserva tras una mutación.
  Future<void> refresh() => _loadReport();

  Future<void> previousWeek() async {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(
      WeeklyReportState(
        weekStart: current.weekStart.subtract(const Duration(days: 7)),
      ),
    );
    await _loadReport();
  }

  Future<void> nextWeek() async {
    final current = state.value;
    if (current == null) {
      return;
    }
    // Don't go beyond current week
    if (!current.weekStart.isBefore(_mondayOfCurrentWeek())) {
      return;
    }

    state = AsyncData(
      WeeklyReportState(
        weekStart: current.weekStart.add(const Duration(days: 7)),
      ),
    );
    await _loadReport();
  }

  bool get canGoNext {
    final current = state.value;
    if (current == null) {
      return false;
    }
    return current.weekStart.isBefore(_mondayOfCurrentWeek());
  }
}
