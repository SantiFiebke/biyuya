import 'package:biyuya/src/core/network/network_timeout.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/models/expense_model.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class ExpenseRepositoryImpl implements ExpenseRepositoryBase {
  const ExpenseRepositoryImpl(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<Result<List<Expense>, ExpenseFailure>> getExpenses({
    required int householdId,
  }) async {
    try {
      final data = await _client
          .from('expenses')
          .select('*, profiles(name)')
          .eq('household_id', householdId)
          .order('date')
          .timeout(kNetworkTimeout);

      final expenses = data.map(ExpenseModel.fromJson).toList();
      return Success(expenses);
    } on Exception catch (e) {
      return Error(ExpenseFailure('Error al obtener gastos: $e'));
    }
  }

  @override
  Future<Result<List<Expense>, ExpenseFailure>> getExpensesByMonth({
    required int householdId,
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final data = await _client
          .from('expenses')
          .select('*, profiles(name)')
          .eq('household_id', householdId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date')
          .timeout(kNetworkTimeout);

      final expenses = data.map(ExpenseModel.fromJson).toList();
      return Success(expenses);
    } on Exception catch (e) {
      return Error(ExpenseFailure('Error al obtener gastos del mes: $e'));
    }
  }

  @override
  Future<Result<List<Expense>, ExpenseFailure>> getExpensesPage({
    required int householdId,
    required int limit,
    required int offset,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? userUuid,
  }) async {
    try {
      var query = _client
          .from('expenses')
          .select('*, profiles(name)')
          .eq('household_id', householdId);

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }
      if (userUuid != null) {
        query = query.eq('user_uuid', userUuid);
      }

      final data = await query
          .order('date', ascending: false)
          .range(offset, offset + limit - 1)
          .timeout(kNetworkTimeout);

      final expenses = data.map(ExpenseModel.fromJson).toList();
      return Success(expenses);
    } on Exception catch (e) {
      return Error(ExpenseFailure('Error al obtener página de gastos: $e'));
    }
  }

  @override
  Future<Result<Expense, ExpenseFailure>> createExpense({
    required double amount,
    required DateTime date,
    required int householdId,
    required int categoryId,
    required String userUuid,
    String? description,
    String? clientId,
  }) async {
    try {
      final data = await _client
          .from('expenses')
          .upsert({
            'amount': amount,
            'date': date.toIso8601String(),
            'description': description,
            'household_id': householdId,
            'category_id': categoryId,
            'user_uuid': userUuid,
            'client_id': clientId,
          }, onConflict: 'client_id')
          .select('*, profiles(name)')
          .single()
          .timeout(kNetworkTimeout);

      return Success(ExpenseModel.fromJson(data));
    } on Exception catch (e) {
      return Error(ExpenseFailure('Error al crear gasto: $e'));
    }
  }

  @override
  Future<Result<Expense, ExpenseFailure>> updateExpense({
    required int id,
    required double amount,
    required DateTime date,
    required int categoryId,
    String? description,
  }) async {
    try {
      final data = await _client
          .from('expenses')
          .update({
            'amount': amount,
            'date': date.toIso8601String(),
            'description': description,
            'category_id': categoryId,
            'last_modified_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select('*, profiles(name)')
          .single()
          .timeout(kNetworkTimeout);

      return Success(ExpenseModel.fromJson(data));
    } on Exception catch (e) {
      return Error(ExpenseFailure('Error al actualizar gasto: $e'));
    }
  }

  @override
  Future<Result<void, ExpenseFailure>> deleteExpense({required int id}) async {
    try {
      await _client
          .from('expenses')
          .delete()
          .eq('id', id)
          .timeout(kNetworkTimeout);
      return const Success(null);
    } on Exception catch (e) {
      return Error(ExpenseFailure('Error al eliminar gasto: $e'));
    }
  }
}
