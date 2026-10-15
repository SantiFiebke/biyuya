import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/domain/entities/savings_report.dart';
import 'package:biyuya/src/features/reports/domain/entities/weekly_report.dart';
import 'package:equatable/equatable.dart';
import 'package:multiple_result/multiple_result.dart';

class ReportFailure extends Equatable {
  const ReportFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

abstract class ReportRepositoryBase {
  /// Obtiene el reporte mensual de gastos del household
  Future<Result<MonthlyReport, ReportFailure>> getMonthlyReport({
    required int householdId,
    required int year,
    required int month,
    required List<Category> categories,
  });

  /// Obtiene el reporte semanal de gastos del household.
  ///
  /// [weekStart] es el primer día de la semana; la semana cubre
  /// `[weekStart, weekStart + 7 días)`.
  Future<Result<WeeklyReport, ReportFailure>> getWeeklyReport({
    required int householdId,
    required DateTime weekStart,
    required List<Category> categories,
  });

  /// Obtiene el reporte de ahorro del household para el mes dado: suma de
  /// movimientos de categorías no-gasto (is_expense = false) y meta derivada
  /// del promedio mensual de gastos de los últimos 3 meses.
  Future<Result<SavingsReport, ReportFailure>> getSavingsReport({
    required int householdId,
    required int year,
    required int month,
  });
}
