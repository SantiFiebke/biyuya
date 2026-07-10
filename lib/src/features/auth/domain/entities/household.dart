import 'package:equatable/equatable.dart';

class Household extends Equatable {
  const Household({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, createdAt];
}
