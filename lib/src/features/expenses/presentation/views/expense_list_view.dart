import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skeletonizer/skeletonizer.dart';

Color? _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) {
    return null;
  }
  final clean = hex.replaceFirst('#', '');
  if (clean.length != 6) {
    return null;
  }
  return Color(int.parse('FF$clean', radix: 16));
}

class ExpenseListView extends ConsumerStatefulWidget {
  const ExpenseListView({super.key});

  @override
  ConsumerState<ExpenseListView> createState() => _ExpenseListViewState();
}

class _ExpenseListViewState extends ConsumerState<ExpenseListView> {
  int? _selectedCategoryId;
  DateTimeRange? _dateRange;

  bool get _hasActiveFilters =>
      _selectedCategoryId != null || _dateRange != null;

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _dateRange = null;
    });
  }

  Future<void> _showCategoryFilter(BuildContext context) async {
    final categories = ref.read(categoryControllerProvider).value ?? [];

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todas las categorías'),
              onTap: () {
                setState(() => _selectedCategoryId = null);
                Navigator.pop(context);
              },
            ),
            ...categories.map(
              (category) => ListTile(
                title: Text(category.name),
                leading: Icon(Icons.circle, color: _parseColor(category.color)),
                onTap: () {
                  setState(() => _selectedCategoryId = category.id);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  List<Expense> _filterExpenses(List<Expense> expenses) {
    var filtered = expenses;

    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((e) => e.categoryId == _selectedCategoryId)
          .toList();
    }

    if (_dateRange != null) {
      filtered = filtered
          .where(
            (e) =>
                e.date.isAfter(_dateRange!.start) &&
                e.date.isBefore(_dateRange!.end.add(const Duration(days: 1))),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final asyncExpenses = ref.watch(expenseControllerProvider);

    ref.listen<AsyncValue<List<Expense>>>(expenseControllerProvider, (
      _,
      state,
    ) {
      state.whenOrNull(
        error: (error, _) {
          context.showErrorSnackBar(error.toString());
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Categoría'),
                  selected: _selectedCategoryId != null,
                  onSelected: (_) => _showCategoryFilter(context),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Fecha'),
                  selected: _dateRange != null,
                  onSelected: (_) => _showDateRangePicker(),
                ),
                if (_hasActiveFilters)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Limpiar'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: asyncExpenses.when(
              loading: () => const _ExpenseSkeleton(),
              error: (error, _) => Center(
                child: Text(
                  'Error al cargar gastos',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              data: (expenses) {
                final filtered = _filterExpenses(expenses);
                if (filtered.isEmpty) {
                  return const EmptyExpenses();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final expense = filtered[index];
                    return ExpenseTile(
                      expense: expense,
                      onTap: () => context.push(
                        '/expenses/edit/${expense.id}',
                        extra: expense,
                      ),
                      onDelete: () => _confirmDelete(context, ref, expense),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/expenses/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text(
          '¿Estás segura de que querés eliminar este gasto de \$${expense.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(expenseControllerProvider.notifier)
          .deleteExpense(id: expense.id);
    }
  }
}

class ExpenseTile extends ConsumerWidget {
  const ExpenseTile({
    required this.expense,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCategories = ref.watch(categoryControllerProvider);
    final categories = asyncCategories.value ?? [];
    final category = categories.cast<Category?>().firstWhere(
      (c) => c?.id == expense.categoryId,
      orElse: () => null,
    );

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // Dialog handles the actual delete
      },
      child: ListTile(
        leading: ExpenseCategoryAvatar(category: category),
        title: Text(
          expense.description ?? 'Sin descripción',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(expense.date)),
        trailing: Text(
          '\$ ${NumberFormat('#,##0.00', 'es_AR').format(expense.amount)}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        onTap: onTap,
      ),
    );
  }
}

class ExpenseCategoryAvatar extends StatelessWidget {
  const ExpenseCategoryAvatar({required this.category, super.key});

  final Category? category;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category?.color);
    final icon = _iconFromCodePoint(category?.icon);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withValues(
          alpha: 0.2,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color ?? Theme.of(context).colorScheme.primary,
        size: 20,
      ),
    );
  }
}

IconData _iconFromCodePoint(String? codePoint) {
  if (codePoint == null) {
    return Icons.category;
  }
  final cp = int.tryParse(codePoint);
  if (cp == null) {
    return Icons.category;
  }
  // Runtime-parsed icon code from DB cannot be const
  // ignore: non_const_argument_for_const_parameter
  return IconData(cp, fontFamily: 'MaterialIcons');
}

class EmptyExpenses extends StatelessWidget {
  const EmptyExpenses({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text('No hay gastos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Registrá uno para empezar.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ExpenseSkeleton extends StatelessWidget {
  const _ExpenseSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 6,
        itemBuilder: (context, index) => ListTile(
          leading: const CircleAvatar(radius: 20),
          title: Container(
            height: 16,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          subtitle: Container(
            height: 12,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          trailing: Container(
            height: 16,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
