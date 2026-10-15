import 'package:equatable/equatable.dart';

class SavingsReport extends Equatable {
  const SavingsReport({
    required this.year,
    required this.month,
    required this.totalSaved,
    required this.goalAmount,
    required this.progressPct,
    required this.entries,
  });

  final int year;
  final int month;
  final double totalSaved;
  final double goalAmount;

  /// (totalSaved / goalAmount) * 100
  final double progressPct;
  final List<SavingsEntry> entries;

  @override
  List<Object?> get props => [
    year,
    month,
    totalSaved,
    goalAmount,
    progressPct,
    entries,
  ];
}

class SavingsEntry extends Equatable {
  const SavingsEntry({
    required this.date,
    required this.amount,
    this.description,
    this.source,
  });

  final DateTime date;
  final double amount;
  final String? description;
  final String? source;

  @override
  List<Object?> get props => [date, amount, description, source];
}
