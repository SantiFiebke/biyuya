import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:equatable/equatable.dart';
import 'package:multiple_result/multiple_result.dart';

class ExpenseFailure extends Equatable {
  const ExpenseFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

abstract class ExpenseRepositoryBase {
  /// Obtiene todos los gastos del household del usuario
  Future<Result<List<Expense>, ExpenseFailure>> getExpenses({
    required int householdId,
  });

  /// Obtiene gastos de un mes específico del household
  Future<Result<List<Expense>, ExpenseFailure>> getExpensesByMonth({
    required int householdId,
    required int year,
    required int month,
  });

  /// Crea un nuevo gasto
  Future<Result<Expense, ExpenseFailure>> createExpense({
    required double amount,
    required DateTime date,
    required int householdId,
    required int categoryId,
    required String userUuid,
    String? description,
  });

  /// Actualiza un gasto existente
  Future<Result<Expense, ExpenseFailure>> updateExpense({
    required int id,
    required double amount,
    required DateTime date,
    required int categoryId,
    String? description,
  });

  /// Elimina un gasto
  Future<Result<void, ExpenseFailure>> deleteExpense({required int id});
}
