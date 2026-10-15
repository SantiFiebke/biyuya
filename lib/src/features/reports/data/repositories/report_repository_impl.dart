import 'package:biyuya/src/features/categories/data/local/category_cache.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/expense_totals.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/domain/entities/savings_report.dart';
import 'package:biyuya/src/features/reports/domain/entities/weekly_category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/weekly_report.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:multiple_result/multiple_result.dart';

class ReportRepositoryImpl implements ReportRepositoryBase {
  const ReportRepositoryImpl(this._expenseRepository);

  final ExpenseRepositoryBase _expenseRepository;

  @override
  Future<Result<MonthlyReport, ReportFailure>> getMonthlyReport({
    required int householdId,
    required int year,
    required int month,
    required List<Category> categories,
  }) async {
    try {
      final currentExpenses = await _fetchExpensesByMonth(
        householdId: householdId,
        year: year,
        month: month,
      );

      final previousMonth = month == 1 ? 12 : month - 1;
      final previousYear = month == 1 ? year - 1 : year;
      final previousExpenses = await _fetchExpensesByMonth(
        householdId: householdId,
        year: previousYear,
        month: previousMonth,
      );

      final excludedIds = excludedCategoryIds(categories);

      final total = sumCountableExpenses(currentExpenses, excludedIds);
      final previousTotal = sumCountableExpenses(previousExpenses, excludedIds);

      final variation = previousTotal > 0
          ? ((total - previousTotal) / previousTotal) * 100
          : 0.0;

      final categoryBreakdowns = _calculateCategoryBreakdowns(
        expenses: currentExpenses,
        previousExpenses: previousExpenses,
        total: total,
        categories: categories,
      );

      return Success(
        MonthlyReport(
          total: total,
          previousTotal: previousTotal,
          variation: variation,
          categoryBreakdowns: categoryBreakdowns,
          year: year,
          month: month,
        ),
      );
    } on Exception catch (e) {
      return Error(ReportFailure('Error al generar reporte: $e'));
    }
  }

  @override
  Future<Result<WeeklyReport, ReportFailure>> getWeeklyReport({
    required int householdId,
    required DateTime weekStart,
    required List<Category> categories,
  }) async {
    try {
      // ponytail: un solo fetch de todos los gastos del hogar y filtro en
      // memoria; una semana cruza meses, así que getExpensesByMonth no sirve.
      // Si el volumen crece, pasar a getExpensesPage con rango de fechas.
      final expenses = await _fetchExpenses(householdId: householdId);

      final weekEnd = weekStart.add(const Duration(days: 7));
      final previousStart = weekStart.subtract(const Duration(days: 7));

      final currentWeek = expenses
          .where((e) => !e.date.isBefore(weekStart) && e.date.isBefore(weekEnd))
          .toList();
      final previousWeek = expenses
          .where(
            (e) =>
                !e.date.isBefore(previousStart) && e.date.isBefore(weekStart),
          )
          .toList();

      final excludedIds = excludedCategoryIds(categories);
      final total = sumCountableExpenses(currentWeek, excludedIds);
      final previousWeekTotal = sumCountableExpenses(previousWeek, excludedIds);
      final variation = previousWeekTotal > 0
          ? ((total - previousWeekTotal) / previousWeekTotal) * 100
          : 0.0;

      return Success(
        WeeklyReport(
          weekStart: weekStart,
          weekEnd: weekEnd,
          total: total,
          previousWeekTotal: previousWeekTotal,
          variation: variation,
          breakdowns: _calculateWeeklyBreakdowns(
            expenses: currentWeek,
            categories: categories,
          ),
          year: weekStart.year,
          week: _weekOfYear(weekStart),
        ),
      );
    } on Exception catch (e) {
      return Error(ReportFailure('Error al generar reporte semanal: $e'));
    }
  }

  @override
  Future<Result<SavingsReport, ReportFailure>> getSavingsReport({
    required int householdId,
    required int year,
    required int month,
  }) async {
    try {
      final categories = await _loadHouseholdCategories(householdId);
      // excludedCategoryIds = categorías no-gasto (is_expense = false): para
      // el reporte de ahorro son los movimientos que suman al total.
      final savingsIds = excludedCategoryIds(categories);
      final categoryNames = {
        for (final category in categories) category.id: category.name,
      };

      final monthExpenses = await _fetchExpensesByMonth(
        householdId: householdId,
        year: year,
        month: month,
      );

      final entries = <SavingsEntry>[
        for (final expense in monthExpenses)
          if (savingsIds.contains(expense.categoryId))
            SavingsEntry(
              date: expense.date,
              amount: expense.amount,
              description: expense.description,
              source: categoryNames[expense.categoryId],
            ),
      ];
      final totalSaved = entries.fold<double>(
        0,
        (sum, entry) => sum + entry.amount,
      );

      // Meta = gasto total de los últimos 3 meses: mes del reporte + los 2
      // anteriores (con cruce de año).
      var windowTotal = sumCountableExpenses(monthExpenses, savingsIds);
      var windowYear = year;
      var windowMonth = month;
      for (var i = 0; i < 2; i++) {
        windowMonth -= 1;
        if (windowMonth < 1) {
          windowMonth = 12;
          windowYear -= 1;
        }
        final previousExpenses = await _fetchExpensesByMonth(
          householdId: householdId,
          year: windowYear,
          month: windowMonth,
        );
        windowTotal += sumCountableExpenses(previousExpenses, savingsIds);
      }
      final goalAmount = windowTotal;
      final progressPct = goalAmount > 0
          ? (totalSaved / goalAmount) * 100
          : 0.0;

      return Success(
        SavingsReport(
          year: year,
          month: month,
          totalSaved: totalSaved,
          goalAmount: goalAmount,
          progressPct: progressPct,
          entries: entries,
        ),
      );
    } on Exception catch (e) {
      return Error(ReportFailure('Error al generar reporte de ahorro: $e'));
    }
  }

  Future<List<Expense>> _fetchExpenses({required int householdId}) async {
    final result = await _expenseRepository.getExpenses(
      householdId: householdId,
    );
    // ponytail: unwrap here so the existing `on Exception` maps any
    // ExpenseFailure to a ReportFailure, igual que _fetchExpensesByMonth.
    return result.when<List<Expense>>(
      (expenses) => expenses,
      (failure) => throw _ExpensesFetchException(failure.message),
    );
  }

  Future<List<Expense>> _fetchExpensesByMonth({
    required int householdId,
    required int year,
    required int month,
  }) async {
    final result = await _expenseRepository.getExpensesByMonth(
      householdId: householdId,
      year: year,
      month: month,
    );
    // ponytail: unwrap here so the existing `on Exception` in getMonthlyReport
    // maps any ExpenseFailure to a ReportFailure.
    return result.when<List<Expense>>(
      (expenses) => expenses,
      (failure) => throw _ExpensesFetchException(failure.message),
    );
  }

  List<CategoryBreakdown> _calculateCategoryBreakdowns({
    required List<Expense> expenses,
    required List<Expense> previousExpenses,
    required double total,
    required List<Category> categories,
  }) {
    final categoryTotals = <int, double>{};
    for (final expense in expenses) {
      final categoryId = expense.categoryId;
      categoryTotals[categoryId] =
          (categoryTotals[categoryId] ?? 0) + expense.amount;
    }

    final previousCategoryTotals = <int, double>{};
    for (final expense in previousExpenses) {
      final categoryId = expense.categoryId;
      previousCategoryTotals[categoryId] =
          (previousCategoryTotals[categoryId] ?? 0) + expense.amount;
    }

    // Unión: categorías presentes en el mes actual O en el anterior.
    final categoryIds = <int>{
      ...categoryTotals.keys,
      ...previousCategoryTotals.keys,
    };

    if (categoryIds.isEmpty) {
      return [];
    }

    final breakdowns = <CategoryBreakdown>[];
    for (final categoryId in categoryIds) {
      final category = categories.where((c) => c.id == categoryId).firstOrNull;
      final amount = categoryTotals[categoryId] ?? 0;
      final previousAmount = previousCategoryTotals[categoryId] ?? 0;
      final isExpense = category?.isExpense ?? true;
      // Categorías no-gasto no consumen % del total de gastos.
      final percentage = isExpense && total > 0 ? (amount / total) * 100 : 0.0;

      breakdowns.add(
        CategoryBreakdown(
          categoryId: categoryId,
          categoryName: category?.name ?? 'Sin categoría',
          categoryColor: category?.color,
          categoryIcon: category?.icon,
          budgetAmount: category?.budgetAmount,
          amount: amount,
          percentage: percentage,
          previousAmount: previousAmount,
          isExpense: isExpense,
        ),
      );
    }

    breakdowns.sort((a, b) => b.amount.compareTo(a.amount));

    return breakdowns;
  }

  List<WeeklyCategoryBreakdown> _calculateWeeklyBreakdowns({
    required List<Expense> expenses,
    required List<Category> categories,
  }) {
    final categoryTotals = <int, double>{};
    for (final expense in expenses) {
      final categoryId = expense.categoryId;
      categoryTotals[categoryId] =
          (categoryTotals[categoryId] ?? 0) + expense.amount;
    }

    final breakdowns = <WeeklyCategoryBreakdown>[];
    for (final entry in categoryTotals.entries) {
      final category = categories.where((c) => c.id == entry.key).firstOrNull;
      breakdowns.add(
        WeeklyCategoryBreakdown.fromBudget(
          categoryId: entry.key,
          categoryName: category?.name ?? 'Sin categoría',
          amount: entry.value,
          // Sin presupuesto cargado: hasBudget false → status ok, sin
          // semáforo en la UI.
          budgetAmount: category?.budgetAmount,
          categoryColor: category?.color,
          categoryIcon: category?.icon,
          isExpense: category?.isExpense ?? true,
        ),
      );
    }

    breakdowns.sort((a, b) => b.amount.compareTo(a.amount));

    return breakdowns;
  }

  /// Categorías del hogar desde la caché local que `categoriesProvider` ya
  /// pobló (la firma de [getSavingsReport] no las recibe).
  Future<List<Category>> _loadHouseholdCategories(int householdId) async {
    final cached = await const CategoryCache().load();
    if (cached == null) {
      return const <Category>[];
    }
    return cached.where((c) => c.householdId == householdId).toList();
  }

  /// Número de semana dentro del año (semanas que empiezan en lunes).
  /// ponytail: no es ISO-8601 (año vecino en semana 1); suficiente para
  /// mostrar "Semana N". Usar cálculo ISO si se necesita intercambio de datos.
  int _weekOfYear(DateTime date) {
    final jan1 = DateTime(date.year);
    final daysSinceMonday = date.difference(jan1).inDays + jan1.weekday - 1;
    return daysSinceMonday ~/ 7 + 1;
  }
}

class _ExpensesFetchException implements Exception {
  const _ExpensesFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}
