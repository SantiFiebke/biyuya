import 'package:biyuya/src/features/reports/domain/entities/weekly_category_breakdown.dart';
import 'package:equatable/equatable.dart';

class WeeklyReport extends Equatable {
  const WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.total,
    required this.previousWeekTotal,
    required this.variation,
    required this.breakdowns,
    required this.year,
    required this.week,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final double total;
  final double previousWeekTotal;
  final double variation; // percentage change vs previous week
  final List<WeeklyCategoryBreakdown> breakdowns;
  final int year;
  final int week;

  bool get hasPreviousData => previousWeekTotal > 0;
  bool get isIncrease => variation > 0;

  @override
  List<Object?> get props => [
    weekStart,
    weekEnd,
    total,
    previousWeekTotal,
    variation,
    breakdowns,
    year,
    week,
  ];
}
