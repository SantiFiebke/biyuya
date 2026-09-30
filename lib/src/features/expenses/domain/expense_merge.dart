import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';

/// Une gastos sincronizados + pendientes (outbox) ordenados por fecha
/// descendente. Copia primero para no mutar las listas de entrada.
List<Expense> mergeExpensesByDateDesc(
  List<Expense> synced,
  List<Expense> pending,
) => [...synced, ...pending]..sort((a, b) => b.date.compareTo(a.date));

/// Subconjunto de [expenses] que cae en [year]/[month].
List<Expense> expensesForMonth(List<Expense> expenses, int year, int month) =>
    expenses
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
