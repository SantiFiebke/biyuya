import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
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
            onPressed: () => context.push('/categories'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onPressed: () {
              // TODO: Profile/settings screen.
            },
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
        onPressed: () => context.push('/expenses/new'),
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
                  onPressed: () => context.push('/expenses'),
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
              return SliverFillRemaining(
                child: _EmptyExpenses(hasCategories: userProfile.hasHousehold),
              );
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
    final householdNameAsync = ref.watch(householdNameProvider);

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
                child: householdNameAsync.when(
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
                  data: (name) => Text(
                    name ?? 'Hogar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar nombre',
                onPressed: () {
                  // TODO: Edit household name
                },
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart_outlined),
                tooltip: 'Reportes',
                onPressed: () => context.push('/reports'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${userProfile.householdId ?? "N/A"}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
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
      subtitle: Text(dateFormat.format(expense.date)),
      trailing: Text(
        amountFormat.format(expense.amount),
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      onTap: () => context.push('/expenses/${expense.id}', extra: expense),
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
        _parseColor(category?.color) ?? Theme.of(context).colorScheme.primary;
    final icon = _iconFromCodePoint(category?.icon);

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

  static const _categoryIcon = Icon(Icons.category);

  IconData _iconFromCodePoint(String? codePoint) {
    if (codePoint == null) {
      return _categoryIcon.icon ?? Icons.category;
    }
    final cp = int.tryParse(codePoint);
    if (cp == null) {
      return _categoryIcon.icon ?? Icons.category;
    }
    // ponytail: dynamic IconData from codePoint can't be const
    // ignore: non_const_argument_for_const_parameter
    return IconData(cp, fontFamily: 'MaterialIcons');
  }
}

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses({required this.hasCategories});

  final bool hasCategories;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay gastos registrados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              ' Registrá tu primer gasto con el botón +',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
