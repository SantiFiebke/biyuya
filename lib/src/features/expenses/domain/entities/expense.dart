import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.amount,
    required this.date,
    required this.householdId,
    required this.categoryId,
    required this.createdAt,
    this.description,
    this.userUuid,
    this.userName,
  });

  final int id;
  final double amount;
  final DateTime date;
  final String? description;
  final int householdId;
  final int categoryId;
  final String? userUuid;
  final String? userName;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    amount,
    date,
    description,
    householdId,
    categoryId,
    userUuid,
    userName,
    createdAt,
  ];
}
