import 'dart:async';

import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
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
class ReportController extends _$ReportController {
  // Invalida respuestas en vuelo: build()/cargas nuevas lo incrementan y una
  // respuesta de un epoch anterior se descarta (evita data de la cuenta
  // anterior en `state` tras un rebuild).
  int _epoch = 0;

  @override
  AsyncValue<ReportState> build() {
    _epoch += 1;
    final now = DateTime.now();
    unawaited(Future.microtask(_loadReport));
    return AsyncData(ReportState(year: now.year, month: now.month));
  }

  Future<void> _loadReport() async {
    _epoch += 1;
    final epoch = _epoch;
    // Capturado antes de AsyncLoading: el loading no conserva value.
    final selected = state.value;
    if (selected == null) {
      return;
    }

    final session = ref.read(authSessionControllerProvider);
    final householdId = session.value?.householdId;

    if (householdId == null || householdId.isEmpty) {
      state = AsyncData(
        ReportState(year: selected.year, month: selected.month),
      );
      return;
    }

    state = const AsyncLoading();
    final repository = ref.read(reportRepositoryProvider);
    final result = await repository.getMonthlyReport(
      householdId: int.parse(householdId),
      year: selected.year,
      month: selected.month,
    );
    if (epoch != _epoch) {
      return;
    }
    result.when(
      (report) => state = AsyncData(
        ReportState(report: report, year: selected.year, month: selected.month),
      ),
      (failure) => state = AsyncError(failure, StackTrace.current),
    );
  }

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
