import 'package:equatable/equatable.dart';

class Household extends Equatable {
  const Household({
    required this.id,
    required this.name,
    required this.createdAt,
    this.inviteCode,
  });

  final String id;
  final String name;
  final String? inviteCode;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, inviteCode, createdAt];
}
