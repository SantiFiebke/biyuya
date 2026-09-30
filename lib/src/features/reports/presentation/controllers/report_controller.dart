import 'dart:async';

import 'package:biyuya/src/core/utils/request_guard.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/provider/categories_provider.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/provider/report_repository_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_controller.g.dart';

/// Estado inmutable del reporte: el mes seleccionado vive en el state (fuente
/// única de verdad), no en campos del notifier — así un rebuild (logout/login)
/// lo resetea junto con `build()`.
class ReportState extends Equatable {
  const ReportState({required this.year, required this.month, this.report});

  final MonthlyReport? report;
  final int year;
  final int month;

  @override
  List<Object?> get props => [report, year, month];
}

@Riverpod(keepAlive: true)
class ReportController extends _$ReportController with RequestGuard {
  @override
  AsyncValue<ReportState> build() {
    invalidateRequests();
    final now = DateTime.now();
    unawaited(Future.microtask(_loadReport));
    return AsyncData(ReportState(year: now.year, month: now.month));
  }

  Future<void> _loadReport() async {
    // Capturado antes de AsyncLoading: el loading no conserva value.
    final selected = state.value;
    if (selected == null) {
      // Sin mes seleccionado (carga en vuelo o estado de error): no-op. NO
      // invalidamos acá: eso descartaría la respuesta en vuelo y dejaría el
      // estado atascado en AsyncLoading.
      return;
    }
    final householdId = ref
        .read(authSessionControllerProvider)
        .value
        ?.householdIdValue;
    if (householdId == null) {
      state = AsyncData(
        ReportState(year: selected.year, month: selected.month),
      );
      return;
    }

    state = const AsyncLoading();
    final result = await runLatest(() async {
      List<Category> categories;
      try {
        categories = await ref.read(categoriesProvider.future);
      } on Object catch (_) {
        categories = const <Category>[];
      }
      return await ref
          .read(reportRepositoryProvider)
          .getMonthlyReport(
            householdId: householdId,
            year: selected.year,
            month: selected.month,
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
        ReportState(report: report, year: selected.year, month: selected.month),
      ),
      (failure) => state = AsyncError(failure, StackTrace.current),
    );
  }

  /// Recarga el reporte del mes seleccionado sin perder la selección.
  /// A diferencia de `invalidate`, no re-ejecuta `build()` (que resetearía el
  /// mes a `DateTime.now()`), así el mes elegido se conserva tras una mutación.
  Future<void> refresh() => _loadReport();

  Future<void> previousMonth() async {
    final current = state.value;
    if (current == null) {
      return;
    }
    final year = current.month == 1 ? current.year - 1 : current.year;
    final month = current.month == 1 ? 12 : current.month - 1;
    state = AsyncData(ReportState(year: year, month: month));
    await _loadReport();
  }

  Future<void> nextMonth() async {
    final current = state.value;
    final now = DateTime.now();
    if (current == null) {
      return;
    }
    // Don't go beyond current month
    if (current.year == now.year && current.month == now.month) {
      return;
    }

    final year = current.month == 12 ? current.year + 1 : current.year;
    final month = current.month == 12 ? 1 : current.month + 1;
    state = AsyncData(ReportState(year: year, month: month));
    await _loadReport();
  }

  bool get canGoNext {
    final current = state.value;
    final now = DateTime.now();
    if (current == null) {
      return false;
    }
    return !(current.year == now.year && current.month == now.month);
  }
}
