import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.householdId,
    required this.createdAt,
    this.color,
    this.icon,
    this.budgetAmount,
  });

  final int id;
  final String name;
  final String? color;
  final String? icon;
  final int householdId;
  final DateTime createdAt;
  final double? budgetAmount;

  @override
  List<Object?> get props => [
    id,
    name,
    color,
    icon,
    householdId,
    createdAt,
    budgetAmount,
  ];
}
