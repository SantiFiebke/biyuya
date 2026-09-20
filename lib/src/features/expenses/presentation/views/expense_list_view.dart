import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/core/presentation/dialogs/confirm_action_dialog.dart';
import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/core/presentation/utils/date_utils.dart';
import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/core/presentation/widgets/category_avatar.dart';
import 'package:biyuya/src/core/presentation/widgets/empty_state.dart';
import 'package:biyuya/src/features/auth/provider/household_members_provider.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/widgets/category_filter_sheet.dart';
import 'package:biyuya/src/features/expenses/presentation/widgets/member_filter_sheet.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:biyuya/theme/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum _ExpenseTileAction { edit, delete }

class ExpenseListView extends ConsumerStatefulWidget {
  const ExpenseListView({super.key});

  @override
  ConsumerState<ExpenseListView> createState() => _ExpenseListViewState();
}

class _ExpenseListViewState extends ConsumerState<ExpenseListView> {
  int? _selectedCategoryId;
  DateTimeRange? _dateRange;
  String? _selectedUserUuid;

  bool get _hasActiveFilters =>
      _selectedCategoryId != null ||
      _dateRange != null ||
      _selectedUserUuid != null;

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _dateRange = null;
      _selectedUserUuid = null;
    });
  }

  Future<void> _showCategoryFilter(BuildContext context) async {
    await showCategoryFilterSheet(
      context,
      ref,
      onSelected: (id) => setState(() => _selectedCategoryId = id),
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

  Future<void> _showMemberFilter(
    BuildContext context,
    List<UserProfile> members,
  ) async {
    final result = await showMemberFilterSheet(
      context,
      members: members,
      selectedUuid: _selectedUserUuid,
    );
    setState(() => _selectedUserUuid = result);
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

    if (_selectedUserUuid != null) {
      filtered = filtered
          .where((e) => e.userUuid == _selectedUserUuid)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final asyncExpenses = ref.watch(expenseControllerProvider);
    final asyncMembers = ref.watch(householdMembersProvider);
    final members = asyncMembers.value ?? [];
    final theme = Theme.of(context);

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

    // Safety reset: orphaned user filter
    ref.listen<AsyncValue<List<UserProfile>>>(householdMembersProvider, (
      _,
      state,
    ) {
      final currentMembers = state.value ?? [];
      final selectedExists =
          _selectedUserUuid != null &&
          currentMembers.any((m) => m.id == _selectedUserUuid);
      if (_selectedUserUuid != null &&
          (!selectedExists || currentMembers.length <= 1)) {
        setState(() => _selectedUserUuid = null);
      }
    });

    final showMemberChip = asyncMembers.hasValue && members.length > 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: Column(
        children: [
          // 1. Filter bar
          FilterBar(
            selectedCategoryId: _selectedCategoryId,
            dateRange: _dateRange,
            selectedUserUuid: _selectedUserUuid,
            showMemberChip: showMemberChip,
            members: members,
            hasActiveFilters: _hasActiveFilters,
            onCategoryTap: () => _showCategoryFilter(context),
            onDateTap: _showDateRangePicker,
            onMemberTap: () => _showMemberFilter(context, members),
            onClear: _clearFilters,
          ),

          // 2. List or skeleton / empty
          Expanded(
            child: asyncExpenses.when(
              loading: () => const _ExpenseSkeleton(),
              error: (error, _) => Center(
                child: Text(
                  'Error al cargar gastos',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              data: (expenses) {
                final filtered = _filterExpenses(expenses);

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No hay gastos',
                    message: 'Probá cambiar los filtros o registrá un gasto',
                    actionLabel: 'Registrar gasto',
                    onAction: () => context.push(AppRoute.expenseNew.path),
                  );
                }

                // 2a. Summary
                final total = filtered.fold<double>(
                  0,
                  (sum, e) => sum + e.amount,
                );
                final expenseColor = Theme.of(
                  context,
                ).extension<AppColors>()?.expense;

                // 2b. List
                return Column(
                  children: [
                    SummaryCard(
                      count: filtered.length,
                      total: total,
                      expenseColor: expenseColor,
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 2),
                        itemBuilder: (context, index) {
                          final expense = filtered[index];
                          return ExpenseListTile(
                            expense: expense,
                            onTap: () => context.push(
                              AppRoute.expenseEdit(expense.id.toString()),
                              extra: expense,
                            ),
                            onDelete: () =>
                                _confirmDelete(context, ref, expense),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () async {
          await HapticFeedback.lightImpact();
          if (context.mounted) {
            await context.push(AppRoute.expenseNew.path);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: 'Eliminar gasto',
      content:
          '¿Estás segura de que querés eliminar este gasto de \$${expense.amount.toStringAsFixed(2)}?',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );
    if (confirmed) {
      final ok = await ref
          .read(expenseControllerProvider.notifier)
          .deleteExpense(id: expense.id);
      if (ok && context.mounted) {
        context.showSuccessSnackBar('Gasto eliminado');
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Dumb widgets
// ---------------------------------------------------------------------------

class FilterBar extends StatelessWidget {
  const FilterBar({
    required this.selectedCategoryId,
    required this.dateRange,
    required this.selectedUserUuid,
    required this.showMemberChip,
    required this.members,
    required this.hasActiveFilters,
    required this.onCategoryTap,
    required this.onDateTap,
    required this.onMemberTap,
    required this.onClear,
    super.key,
  });

  final int? selectedCategoryId;
  final DateTimeRange? dateRange;
  final String? selectedUserUuid;
  final bool showMemberChip;
  final List<UserProfile> members;
  final bool hasActiveFilters;
  final VoidCallback onCategoryTap;
  final VoidCallback onDateTap;
  final VoidCallback onMemberTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final memberName = selectedUserUuid != null
        ? members.firstWhere((m) => m.id == selectedUserUuid).name
        : null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        spacing: 8,
        children: [
          _FilterChipItem(
            label: 'Categoría',
            icon: Icons.category_outlined,
            selected: selectedCategoryId != null,
            onTap: () async {
              await HapticFeedback.selectionClick();
              onCategoryTap();
            },
          ),
          _FilterChipItem(
            label: 'Fecha',
            icon: Icons.date_range_outlined,
            selected: dateRange != null,
            onTap: () async {
              await HapticFeedback.selectionClick();
              onDateTap();
            },
          ),
          if (showMemberChip)
            _FilterChipItem(
              label: memberName ?? 'Usuario',
              icon: Icons.person_outline,
              selected: selectedUserUuid != null,
              onTap: () async {
                await HapticFeedback.selectionClick();
                onMemberTap();
              },
            ),
          if (hasActiveFilters)
            ActionChip(
              avatar: Icon(Icons.close, size: 16, color: scheme.error),
              label: Text(
                'Limpiar',
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
              ),
              onPressed: () async {
                await HapticFeedback.selectionClick();
                onClear();
              },
            ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FilterChip(
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      selected: selected,
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
      side: BorderSide(
        color: selected ? scheme.primaryContainer : scheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onTap(),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.count,
    required this.total,
    this.expenseColor,
    super.key,
  });

  final int count;
  final double total;
  final Color? expenseColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              '$count ${count == 1 ? 'movimiento' : 'movimientos'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            AmountText(
              amount: total,
              color: expenseColor,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseListTile extends ConsumerWidget {
  const ExpenseListTile({
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
    final expenseColor = Theme.of(context).extension<AppColors>()?.expense;
    final icon = iconFromCodePoint(category?.icon);
    final color = parseCategoryColor(category?.color);

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
        return false;
      },
      child: ListTile(
        leading: CategoryAvatar(icon: icon, color: color),
        title: Text(
          expense.description ?? category?.name ?? 'Sin descripción',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${category?.name ?? ''} · ${formatHumanDate(expense.date)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AmountText(amount: expense.amount, color: expenseColor),
            const SizedBox(width: 4),
            PopupMenuButton<_ExpenseTileAction>(
              tooltip: 'Más opciones',
              onSelected: (action) {
                switch (action) {
                  case _ExpenseTileAction.edit:
                    onTap();
                  case _ExpenseTileAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _ExpenseTileAction.edit,
                  child: Text('Editar'),
                ),
                PopupMenuItem(
                  value: _ExpenseTileAction.delete,
                  child: Text(
                    'Eliminar',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
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
