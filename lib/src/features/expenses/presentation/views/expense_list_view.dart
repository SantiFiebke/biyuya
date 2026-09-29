import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/core/presentation/dialogs/confirm_action_dialog.dart';
import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/core/presentation/utils/date_utils.dart';
import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/core/presentation/widgets/category_avatar.dart';
import 'package:biyuya/src/core/presentation/widgets/duplicate_warning_badge.dart';
import 'package:biyuya/src/core/presentation/widgets/empty_view.dart';
import 'package:biyuya/src/core/presentation/widgets/error_view.dart';
import 'package:biyuya/src/core/presentation/widgets/pending_badge.dart';
import 'package:biyuya/src/features/auth/provider/household_members_provider.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/utils/duplicate_detection.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_list_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/widgets/category_filter_sheet.dart';
import 'package:biyuya/src/features/expenses/presentation/widgets/debt_settlement_sheet.dart';
import 'package:biyuya/src/features/expenses/presentation/widgets/member_filter_sheet.dart';
import 'package:biyuya/src/features/expenses/provider/debt_settlement_provider.dart';
import 'package:biyuya/src/features/settings/presentation/controllers/settings_controller.dart';
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
  final ScrollController _scrollController = ScrollController();

  int? _selectedCategoryId;
  DateTimeRange? _dateRange;
  String? _selectedUserUuid;

  /// El controller auto-refresca al construirse y no expone flag de loading,
  /// así que el view re-emite refresh() (en un microtask posterior al del
  /// controller) y lo espera para saber cuándo llegó la primera página.
  /// ponytail: el guard de epoch del controller descarta su carga en vuelo —
  /// sin request extra, solo una segunda lectura del outbox.
  bool _initialLoadStarted = false;
  bool _initialLoadDone = false;

  bool get _hasActiveFilters =>
      _selectedCategoryId != null ||
      _dateRange != null ||
      _selectedUserUuid != null;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearBottom);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreNearBottom)
      ..dispose();
    super.dispose();
  }

  /// Pide la siguiente página cuando el usuario está a ~300px del final.
  /// `loadMore` es no-op sin `hasMore` o con una carga en vuelo, así que
  /// llamar de más es seguro.
  void _loadMoreNearBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 300) {
      return;
    }
    unawaited(ref.read(expenseListControllerProvider.notifier).loadMore());
  }

  Future<void> _refresh() {
    return ref.read(expenseListControllerProvider.notifier).refresh();
  }

  void _startInitialLoad() {
    if (_initialLoadStarted) {
      return;
    }
    _initialLoadStarted = true;
    // Vuelta a la pantalla con página ya cargada: no recargar.
    if (ref.read(expenseListControllerProvider).items.isNotEmpty) {
      _initialLoadDone = true;
      return;
    }
    unawaited(Future.microtask(_settleInitialLoad));
  }

  Future<void> _settleInitialLoad() async {
    if (!mounted) {
      return;
    }
    await _refresh();
    if (!mounted || _initialLoadDone) {
      return;
    }
    setState(() => _initialLoadDone = true);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _dateRange = null;
      _selectedUserUuid = null;
    });
    unawaited(ref.read(expenseListControllerProvider.notifier).clearFilters());
  }

  void _onCategorySelected(int? id) {
    if (id == _selectedCategoryId) {
      return;
    }
    setState(() => _selectedCategoryId = id);
    final notifier = ref.read(expenseListControllerProvider.notifier);
    if (id == null) {
      unawaited(notifier.setFilters(clearCategory: true));
    } else {
      unawaited(notifier.setFilters(categoryId: id));
    }
  }

  Future<void> _showCategoryFilter(BuildContext context) async {
    await showCategoryFilterSheet(
      context,
      ref,
      selectedCategoryId: _selectedCategoryId,
      onSelected: _onCategorySelected,
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) {
      return;
    }
    setState(() => _dateRange = picked);
    // `lte` es inclusivo: cerrar el rango al final del día elegido, igual que
    // el filtro in-memory viejo (`isBefore(end + 1 día)`).
    final endDate = DateTime(
      picked.end.year,
      picked.end.month,
      picked.end.day,
      23,
      59,
      59,
    );
    unawaited(
      ref
          .read(expenseListControllerProvider.notifier)
          .setFilters(startDate: picked.start, endDate: endDate),
    );
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
    if (result == _selectedUserUuid) {
      return;
    }
    setState(() => _selectedUserUuid = result);
    final notifier = ref.read(expenseListControllerProvider.notifier);
    if (result == null) {
      unawaited(notifier.setFilters(clearUser: true));
    } else {
      unawaited(notifier.setFilters(userUuid: result));
    }
  }

  Future<void> _showDebtSettlement() async {
    final now = DateTime.now();
    final transfers = ref.read(
      debtSettlementProvider(year: now.year, month: now.month),
    );
    await showDebtSettlementSheet(context, transfers: transfers);
  }

  Future<void> _retrySync() async {
    await ref.read(expenseControllerProvider.notifier).retrySync();
    if (!mounted) {
      return;
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(expenseListControllerProvider);
    _startInitialLoad();

    final asyncMembers = ref.watch(householdMembersProvider);
    final members = asyncMembers.value ?? [];
    final categories = ref.watch(categoryControllerProvider).value ?? [];

    ref.listen(expenseListControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && error != previous?.error) {
        context.showErrorSnackBar(error.toString());
      }
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
        unawaited(
          ref
              .read(expenseListControllerProvider.notifier)
              .setFilters(clearUser: true),
        );
      }
    });

    final showMemberChip = asyncMembers.hasValue && members.length > 1;
    final debtSettlementEnabled =
        ref.watch(settingsControllerProvider).value?.debtSettlementEnabled ??
        false;
    final hasPendingSync = listState.items.any(
      (e) => e.syncStatus != ExpenseSyncStatus.synced,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        actions: [
          if (debtSettlementEnabled)
            TextButton.icon(
              onPressed: _showDebtSettlement,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Liquidar deudas'),
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Filter bar (chips espejo de los filtros server-side)
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

          // 2. Retry sync (only when there is something pending)
          if (hasPendingSync)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextButton.icon(
                  onPressed: () => unawaited(_retrySync()),
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Reintentar sync'),
                ),
              ),
            ),

          // 3. List / empty / error, con pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: listState.error != null && listState.items.isEmpty
                  ? ErrorView(
                      message: 'No se pudieron cargar los gastos',
                      retryLabel: 'Reintentar',
                      onRetry: () => unawaited(_refresh()),
                    )
                  : listState.items.isEmpty
                  ? (_initialLoadDone
                        ? EmptyView(
                            title: 'Todavía no hay gastos',
                            message: 'Registrá tu primer gasto para empezar',
                            actionLabel: 'Registrar gasto',
                            onAction: () =>
                                context.push(AppRoute.expenseNew.path),
                          )
                        : const _ExpenseSkeleton())
                  : _ExpenseListBody(
                      expenses: listState.items,
                      categories: categories,
                      isLoadingMore: listState.isLoadingMore,
                      scrollController: _scrollController,
                      onTap: (expense) => context.push(
                        AppRoute.expenseEdit(expense.id.toString()),
                        extra: expense,
                      ),
                      onDelete: (expense) =>
                          _confirmDelete(context, ref, expense),
                    ),
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
      if (ok) {
        await ref.read(expenseListControllerProvider.notifier).refresh();
      }
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

/// Lista paginada: tiles + footer con spinner mientras `isLoadingMore`.
class _ExpenseListBody extends StatelessWidget {
  const _ExpenseListBody({
    required this.expenses,
    required this.categories,
    required this.isLoadingMore,
    required this.scrollController,
    required this.onTap,
    required this.onDelete,
  });

  final List<Expense> expenses;
  final List<Category> categories;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final ValueChanged<Expense> onTap;
  final ValueChanged<Expense> onDelete;

  @override
  Widget build(BuildContext context) {
    // Duplicados sobre lo cargado hasta ahora: cada página agregada los
    // re-evalúa (barato) y el badge solo cubre lo visible.
    final duplicateIds = findDuplicateExpenseIds(expenses);

    return ListView.separated(
      controller: scrollController,
      // Siempre scrolleable: pull-to-refresh aunque quepa en pantalla.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: expenses.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        if (index >= expenses.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final expense = expenses[index];
        final category = categories.cast<Category?>().firstWhere(
          (c) => c?.id == expense.categoryId,
          orElse: () => null,
        );
        return ExpenseListTile(
          expense: expense,
          category: category,
          isDuplicate: duplicateIds.contains(expense.id),
          onTap: () => onTap(expense),
          onDelete: () => onDelete(expense),
        );
      },
    );
  }
}

class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({
    required this.expense,
    required this.category,
    required this.isDuplicate,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Expense expense;
  final Category? category;
  final bool isDuplicate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final expenseColor = Theme.of(context).extension<AppColors>()?.expense;
    final icon = iconFromCodePoint(category?.icon);
    final color = parseCategoryColor(category?.color);
    final hasBadges =
        isDuplicate || expense.syncStatus != ExpenseSyncStatus.synced;

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
        isThreeLine: hasBadges,
        leading: CategoryAvatar(icon: icon, color: color),
        title: Text(
          expense.description ?? category?.name ?? 'Sin descripción',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // single ellipsized line; long category may ellipsize the
            // date too, acceptable — full data lives in the detail view.
            Text(
              '${category?.name ?? ''} · ${formatHumanDate(expense.date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (hasBadges)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (isDuplicate) const DuplicateWarningBadge(),
                    if (expense.syncStatus != ExpenseSyncStatus.synced)
                      const PendingBadge(),
                  ],
                ),
              ),
          ],
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AmountText(amount: expense.amount, color: expenseColor),
              ),
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
