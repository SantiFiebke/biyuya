import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.householdId,
    required this.createdAt,
    this.color,
    this.icon,
  });

  final int id;
  final String name;
  final String? color;
  final String? icon;
  final int householdId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, color, icon, householdId, createdAt];
}
