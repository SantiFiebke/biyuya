import 'dart:async';

import 'package:biyuya/src/core/utils/request_guard.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/reports/domain/entities/savings_report.dart';
import 'package:biyuya/src/features/reports/provider/report_repository_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'savings_report_controller.g.dart';

/// Estado inmutable del reporte de ahorro: el mes seleccionado vive en el
/// state (fuente única de verdad), no en campos del notifier — así un rebuild
/// (logout/login) lo resetea junto con `build()`.
class SavingsReportState extends Equatable {
  const SavingsReportState({
    required this.year,
    required this.month,
    this.report,
  });

  final SavingsReport? report;
  final int year;
  final int month;

  @override
  List<Object?> get props => [report, year, month];
}

@Riverpod(keepAlive: true)
class SavingsReportController extends _$SavingsReportController
    with RequestGuard {
  @override
  AsyncValue<SavingsReportState> build() {
    invalidateRequests();
    final now = DateTime.now();
    unawaited(Future.microtask(_loadReport));
    return AsyncData(SavingsReportState(year: now.year, month: now.month));
  }

  Future<void> _loadReport() async {
    // Capturado antes del AsyncLoading: fija qué mes dispara esta carga.
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
        SavingsReportState(year: selected.year, month: selected.month),
      );
      return;
    }

    // Retiene el reporte anterior durante la recarga (sin salto de layout).
    // ignore: invalid_use_of_internal_member
    state = const AsyncLoading<SavingsReportState>().copyWithPrevious(state);
    final result = await runLatest(
      () => ref
          .read(reportRepositoryProvider)
          .getSavingsReport(
            householdId: householdId,
            year: selected.year,
            month: selected.month,
          ),
    );
    if (result == null) {
      return; // obsoleta: arrancó otra carga
    }
    if (!ref.mounted) {
      return;
    }
    result.when(
      (report) => state = AsyncData(
        SavingsReportState(
          report: report,
          year: selected.year,
          month: selected.month,
        ),
      ),
      (failure) => state = AsyncError(failure, StackTrace.current),
    );
  }

  /// Recarga el reporte del mes seleccionado sin perder la selección.
  /// A diferencia de `invalidate`, no re-ejecuta `build()` (que resetearía el
  /// mes a `DateTime.now()`), así el mes elegido se conserva tras una mutación.
  Future<void> refresh() => _loadReport();
}
