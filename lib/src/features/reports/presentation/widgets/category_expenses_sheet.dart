import 'dart:async';

import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/reports/domain/entities/category_breakdown.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

class CategoryExpensesSheet extends ConsumerWidget {
  const CategoryExpensesSheet({
    required this.breakdown,
    required this.year,
    required this.month,
    super.key,
  });

  final CategoryBreakdown breakdown;
  final int year;
  final int month;

  static Future<void> show(
    BuildContext context, {
    required CategoryBreakdown breakdown,
    required int year,
    required int month,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          CategoryExpensesSheet(breakdown: breakdown, year: year, month: month),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseControllerProvider);
    final allExpenses = expensesAsync.value ?? [];
    final filtered = allExpenses
        .where((e) => e.categoryId == breakdown.categoryId)
        .toList();

    return _CategoryExpensesSheetContent(
      breakdown: breakdown,
      filteredExpenses: filtered,
    );
  }
}

class _CategoryExpensesSheetContent extends StatelessWidget {
  const _CategoryExpensesSheetContent({
    required this.breakdown,
    required this.filteredExpenses,
  });

  final CategoryBreakdown breakdown;
  final List<Expense> filteredExpenses;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: r'$',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy');
    final total = filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    breakdown.categoryName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  currencyFormat.format(total),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: filteredExpenses.isEmpty
                ? const Center(child: Text('No hay gastos para esta categoría'))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filteredExpenses.length,
                    itemBuilder: (_, index) {
                      final expense = filteredExpenses[index];
                      return ListTile(
                        title: Text(expense.description ?? 'Sin descripción'),
                        subtitle: Text(dateFormat.format(expense.date)),
                        trailing: Text(currencyFormat.format(expense.amount)),
                        onTap: () {
                          Navigator.of(context).pop();
                          unawaited(
                            context.push(
                              AppRoute.expenseDetail(expense.id.toString()),
                              extra: expense,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
