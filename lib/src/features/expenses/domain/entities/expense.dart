import 'package:equatable/equatable.dart';

enum ExpenseSyncStatus { synced, pending, failed }

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
    this.clientId,
    this.syncStatus = ExpenseSyncStatus.synced,
  });

  factory Expense.pending({
    required double amount,
    required DateTime date,
    required int householdId,
    required int categoryId,
    required String clientId,
    String? description,
    String? userUuid,
    String? userName,
  }) {
    return Expense(
      id: -DateTime.now().microsecondsSinceEpoch,
      amount: amount,
      date: date,
      householdId: householdId,
      categoryId: categoryId,
      clientId: clientId,
      syncStatus: ExpenseSyncStatus.pending,
      createdAt: DateTime.now(),
      description: description,
      userUuid: userUuid,
      userName: userName,
    );
  }

  final int id;
  final double amount;
  final DateTime date;
  final String? description;
  final int householdId;
  final int categoryId;
  final String? userUuid;
  final String? userName;
  final DateTime createdAt;
  final String? clientId;
  final ExpenseSyncStatus syncStatus;

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
    clientId,
    syncStatus,
  ];
}
