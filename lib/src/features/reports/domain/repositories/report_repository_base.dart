import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
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
}
