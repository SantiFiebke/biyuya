import 'dart:async';

import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/core/presentation/utils/date_utils.dart';
import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/core/presentation/widgets/category_avatar.dart';
import 'package:biyuya/src/core/presentation/widgets/empty_state.dart';
import 'package:biyuya/src/features/auth/domain/entities/household_data.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/home/presentation/widgets/edit_household_dialog.dart';
import 'package:biyuya/src/features/home/presentation/widgets/invite_code_sheet.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:biyuya/theme/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionControllerProvider);
    final expenses = ref.watch(expenseControllerProvider);
    final household = ref.watch(householdNameProvider);
    final categories = ref.watch(categoryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas claras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Categorías',
            onPressed: () => context.push(AppRoute.categories.path),
          ),
        ],
      ),
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (userProfile) {
          if (userProfile == null) {
            return const SizedBox();
          }
          return _HomeContent(
            expenses: expenses,
            household: household,
            categories: categories.value ?? [],
            onEditHousehold: () => showEditHouseholdDialog(context, ref),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          unawaited(HapticFeedback.lightImpact());
          unawaited(context.push(AppRoute.expenseNew.path));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home content (dumb widget — all data comes from parent)
// ---------------------------------------------------------------------------
class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.expenses,
    required this.household,
    required this.categories,
    required this.onEditHousehold,
  });

  final AsyncValue<List<Expense>> expenses;
  final AsyncValue<HouseholdData?> household;
  final List<Category> categories;
  final VoidCallback onEditHousehold;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expenseList = expenses.value ?? [];
    final monthlyTotal = expenseList
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final categoryMap = {for (final c in categories) c.id: c};

    return CustomScrollView(
      slivers: [
        // 1. Balance card
        SliverToBoxAdapter(
          child: _BalanceCard(
            monthlyTotal: monthlyTotal,
            household: household,
            onEditHousehold: onEditHousehold,
          ),
        ),
        // 2. Quick actions
        const SliverToBoxAdapter(child: _QuickActions()),
        // 3. Section header
        const SliverToBoxAdapter(child: _SectionHeader()),
        // 4. Expense list / empty / skeleton
        expenses.when(
          loading: () => const SliverFillRemaining(child: _HomeSkeleton()),
          error: (_, _) => const SliverFillRemaining(
            child: Center(child: Text('Error al cargar gastos')),
          ),
          data: (list) {
            if (list.isEmpty) {
              return SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Todavía no hay gastos',
                  message: 'Registrá tu primer gasto para empezar',
                  actionLabel: 'Registrar gasto',
                  onAction: () => context.push(AppRoute.expenseNew.path),
                ),
              );
            }
            final sorted = List<Expense>.from(list)
              ..sort((a, b) => b.date.compareTo(a.date));
            final top5 = sorted.take(5).toList();
            return SliverPadding(
              padding: const EdgeInsets.only(bottom: 80),
              sliver: SliverList.separated(
                itemCount: top5.length,
                separatorBuilder: (_, _) => const SizedBox.shrink(),
                itemBuilder: (_, i) => _ExpenseItem(
                  expense: top5[i],
                  category: categoryMap[top5[i].categoryId],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Balance card
// ---------------------------------------------------------------------------
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.monthlyTotal,
    required this.household,
    required this.onEditHousehold,
  });

  final double monthlyTotal;
  final AsyncValue<HouseholdData?> household;
  final VoidCallback onEditHousehold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      color: cs.primary,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              'Gastado este mes',
              style: theme.textTheme.titleSmall?.copyWith(
                color: cs.onPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 4),
            // Amount
            AmountText(
              amount: monthlyTotal,
              color: cs.onPrimary,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Household row
            household.when(
              loading: () => _HouseholdRow(
                name: 'Hogar',
                inviteCode: null,
                onInvite: null,
                onEdit: onEditHousehold,
              ),
              error: (_, _) => _HouseholdRow(
                name: 'Hogar',
                inviteCode: null,
                onInvite: null,
                onEdit: onEditHousehold,
              ),
              data: (data) => _HouseholdRow(
                name: data?.name ?? 'Hogar',
                inviteCode: data?.inviteCode,
                onInvite: data?.inviteCode != null
                    ? () => InviteCodeSheet.show(
                        context,
                        inviteCode: data!.inviteCode!,
                      )
                    : null,
                onEdit: onEditHousehold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HouseholdRow extends StatelessWidget {
  const _HouseholdRow({
    required this.name,
    required this.inviteCode,
    required this.onInvite,
    required this.onEdit,
  });

  final String name;
  final String? inviteCode;
  final VoidCallback? onInvite;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.home_outlined, color: cs.onPrimary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onInvite != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.share_outlined, color: cs.onPrimary, size: 20),
            tooltip: 'Invitar',
            onPressed: onInvite,
          ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.edit_outlined, color: cs.onPrimary, size: 20),
          tooltip: 'Editar nombre',
          onPressed: onEdit,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Quick actions
// ---------------------------------------------------------------------------
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.add_circle_outline,
              label: 'Nuevo gasto',
              backgroundColor: cs.primaryContainer,
              iconColor: cs.onPrimaryContainer,
              onTap: () {
                unawaited(HapticFeedback.lightImpact());
                unawaited(context.push(AppRoute.expenseNew.path));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickAction(
              icon: Icons.bar_chart_rounded,
              label: 'Reportes',
              backgroundColor: cs.primaryContainer,
              iconColor: cs.onPrimaryContainer,
              onTap: () {
                unawaited(HapticFeedback.lightImpact());
                context.go(AppRoute.reports.path);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickAction(
              icon: Icons.category_outlined,
              label: 'Categorías',
              backgroundColor: cs.surfaceContainerHighest,
              iconColor: cs.onSurfaceVariant,
              onTap: () {
                unawaited(HapticFeedback.lightImpact());
                unawaited(context.push(AppRoute.categories.path));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Section header
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Últimos movimientos',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () => context.go(AppRoute.expenses.path),
            child: const Text('Ver todos'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Expense item
// ---------------------------------------------------------------------------
class _ExpenseItem extends StatelessWidget {
  const _ExpenseItem({required this.expense, required this.category});

  final Expense expense;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final expenseColor = Theme.of(context).extension<AppColors>()?.expense;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CategoryAvatar(
          icon: iconFromCodePoint(category?.icon),
          color: parseCategoryColor(category?.color),
        ),
        title: Text(
          expense.description ?? category?.name ?? 'Sin descripción',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${category?.name ?? ''} · ${formatHumanDate(expense.date)}',
        ),
        trailing: AmountText(amount: expense.amount, color: expenseColor),
        onTap: () => context.push(
          AppRoute.expenseDetail(expense.id.toString()),
          extra: expense,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Fake card
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Fake list tiles
            ...List.generate(
              4,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(radius: 20),
                  title: _SkeletonBox(width: 160, height: 14),
                  subtitle: _SkeletonBox(width: 100, height: 10),
                  trailing: _SkeletonBox(width: 60, height: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
