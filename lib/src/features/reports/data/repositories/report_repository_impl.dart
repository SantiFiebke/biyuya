import 'package:biyuya/src/core/network/network_timeout.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/domain/repositories/category_repository_base.dart';
import 'package:biyuya/src/features/expenses/domain/expense_totals.dart';
import 'package:biyuya/src/features/expenses/domain/models/expense_model.dart';
import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class ReportRepositoryImpl implements ReportRepositoryBase {
  const ReportRepositoryImpl(this._client, this._categoryRepository);

  final supabase.SupabaseClient _client;
  final CategoryRepositoryBase _categoryRepository;

  @override
  Future<Result<MonthlyReport, ReportFailure>> getMonthlyReport({
    required int householdId,
    required int year,
    required int month,
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

      final categories = await _loadCategories(householdId);
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

  Future<List<ExpenseModel>> _fetchExpensesByMonth({
    required int householdId,
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final data = await _client
        .from('expenses')
        .select()
        .eq('household_id', householdId)
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String())
        .timeout(kNetworkTimeout);

    return data.map(ExpenseModel.fromJson).toList();
  }

  Future<List<Category>> _loadCategories(int householdId) async {
    final result = await _categoryRepository.getCategories(
      householdId: householdId,
    );
    // ponytail: local avoids R inferring as Future from the return context.
    final categories = result.when((cats) => cats, (_) => <Category>[]);
    return categories;
  }

  List<CategoryBreakdown> _calculateCategoryBreakdowns({
    required List<ExpenseModel> expenses,
    required List<ExpenseModel> previousExpenses,
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
}
