import 'dart:convert';

import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Outbox of expenses awaiting sync, backed by [SharedPreferences].
///
/// Plain class (no Riverpod annotation) so it can be injected.
class PendingExpenseStore {
  const PendingExpenseStore();

  static const _key = 'pending_expenses';

  Future<List<Expense>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<Expense> pending) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(pending.map(_toJson).toList());
    await prefs.setString(_key, encoded);
  }

  Future<void> add(Expense expense) async {
    final pending = await load();
    await save([...pending, expense]);
  }

  Future<void> remove(String clientId) async {
    final pending = await load();
    await save(pending.where((e) => e.clientId != clientId).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // Full map including id/created_at/sync_status, unlike ExpenseModel.toJson
  // (insert payload).
  Map<String, dynamic> _toJson(Expense expense) {
    return {
      'id': expense.id,
      'client_id': expense.clientId,
      'amount': expense.amount,
      'date': expense.date.toIso8601String(),
      'description': expense.description,
      'household_id': expense.householdId,
      'category_id': expense.categoryId,
      'user_uuid': expense.userUuid,
      'user_name': expense.userName,
      'created_at': expense.createdAt.toIso8601String(),
      'sync_status': expense.syncStatus.name,
    };
  }

  Expense _fromJson(Map<String, dynamic> json) {
    return Expense(
      id: (json['id'] as num).toInt(),
      clientId: json['client_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      householdId: (json['household_id'] as num).toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      userUuid: json['user_uuid'] as String?,
      userName: json['user_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      syncStatus: ExpenseSyncStatus.values.byName(
        json['sync_status'] as String,
      ),
    );
  }
}
