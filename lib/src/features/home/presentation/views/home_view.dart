import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/views/expense_list_view.dart';
import 'package:biyuya/src/features/home/presentation/widgets/edit_household_dialog.dart';
import 'package:biyuya/src/features/home/presentation/widgets/invite_code_sheet.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionControllerProvider);
    final expenses = ref.watch(expenseControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas claras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Categorías',
            onPressed: () => context.push(AppRoute.categories.path),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onPressed: () => context.push(AppRoute.profile.path),
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
          return _HomeContent(userProfile: userProfile, expenses: expenses);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoute.expenseNew.path),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.userProfile, required this.expenses});

  final UserProfile userProfile;
  final AsyncValue<List<Expense>> expenses;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Household header
        SliverToBoxAdapter(child: _HouseholdHeader(userProfile: userProfile)),
        // Expenses section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Últimos gastos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoute.expenses.path),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
          ),
        ),
        // Expenses list or empty state
        expenses.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => const SliverFillRemaining(
            child: Center(child: Text('Error al cargar gastos')),
          ),
          data: (expenseList) {
            if (expenseList.isEmpty) {
              return const SliverFillRemaining(child: EmptyExpenses());
            }
            final recentExpenses = expenseList.take(15).toList();
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index < recentExpenses.length) {
                  return _RecentExpenseTile(expense: recentExpenses[index]);
                }
                return null;
              }, childCount: recentExpenses.length),
            );
          },
        ),
      ],
    );
  }
}

class _HouseholdHeader extends ConsumerWidget {
  const _HouseholdHeader({required this.userProfile});

  final UserProfile userProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdDataAsync = ref.watch(householdNameProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.home_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: householdDataAsync.when(
                  loading: () => Text(
                    'Hogar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  error: (_, _) => Text(
                    'Hogar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  data: (data) => Row(
                    children: [
                      Text(
                        data?.name ?? 'Hogar',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      householdDataAsync.when(
                        loading: () => const SizedBox(),
                        error: (_, _) => const SizedBox(),
                        data: (data) {
                          if (data?.inviteCode == null) {
                            return const SizedBox();
                          }
                          return IconButton(
                            icon: const Icon(Icons.person_add, size: 20),
                            tooltip: 'Compartir código',
                            onPressed: () {
                              InviteCodeSheet.show(
                                context,
                                inviteCode: data!.inviteCode!,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar nombre',
                onPressed: () => showEditHouseholdDialog(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart_outlined),
                tooltip: 'Reportes',
                onPressed: () => context.push(AppRoute.reports.path),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentExpenseTile extends StatelessWidget {
  const _RecentExpenseTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final amountFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: r'$',
      decimalDigits: 2,
    );

    return ListTile(
      leading: _ExpenseCategoryIcon(categoryId: expense.categoryId),
      title: Text(
        expense.description ?? 'Sin descripción',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (expense.userName != null) expense.userName,
          dateFormat.format(expense.date),
        ].join(' · '),
      ),
      trailing: Text(
        amountFormat.format(expense.amount),
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      onTap: () => context.push(
        AppRoute.expenseDetail(expense.id.toString()),
        extra: expense,
      ),
    );
  }
}

class _ExpenseCategoryIcon extends ConsumerWidget {
  const _ExpenseCategoryIcon({required this.categoryId});

  final int categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryControllerProvider);
    final category = categories.value
        ?.where((c) => c.id == categoryId)
        .firstOrNull;

    final color =
        parseCategoryColor(category?.color) ??
        Theme.of(context).colorScheme.primary;
    final icon = iconFromCodePoint(category?.icon);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
