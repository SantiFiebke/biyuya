import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:equatable/equatable.dart';

class MonthlyReport extends Equatable {
  const MonthlyReport({
    required this.total,
    required this.previousTotal,
    required this.variation,
    required this.categoryBreakdowns,
    required this.year,
    required this.month,
  });

  final double total;
  final double previousTotal;
  final double variation; // percentage change vs previous month
  final List<CategoryBreakdown> categoryBreakdowns;
  final int year;
  final int month;

  bool get hasPreviousData => previousTotal > 0;
  bool get isIncrease => variation > 0;

  @override
  List<Object?> get props => [
    total,
    previousTotal,
    variation,
    categoryBreakdowns,
    year,
    month,
  ];
}
