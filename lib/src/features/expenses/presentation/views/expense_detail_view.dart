import 'package:biyuya/src/core/presentation/utils/date_utils.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

class ExpenseDetailView extends ConsumerWidget {
  const ExpenseDetailView({required this.expense, super.key});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryControllerProvider);
    final category = categories.value
        ?.where((c) => c.id == expense.categoryId)
        .firstOrNull;

    final amountFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: r'$',
      decimalDigits: 2,
    );

    final isPending = expense.syncStatus != ExpenseSyncStatus.synced;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del gasto'),
        actions: [
          if (!isPending)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => context.push(
                AppRoute.expenseEdit(expense.id.toString()),
                extra: expense,
              ),
            ),
          if (isPending)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Descartar',
              onPressed: () async {
                final clientId = expense.clientId;
                if (clientId == null) {
                  return;
                }
                await ref
                    .read(expenseControllerProvider.notifier)
                    .discardPending(clientId);
                if (context.mounted) {
                  context.pop();
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    amountFormat.format(expense.amount),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Details
            _DetailRow(
              label: 'Descripción',
              value: expense.description ?? 'Sin descripción',
            ),
            const Divider(height: 32),

            _DetailRow(
              label: 'Categoría',
              value: category?.name ?? 'Sin categoría',
            ),
            const Divider(height: 32),

            _DetailRow(label: 'Fecha', value: formatHumanDate(expense.date)),
            const Divider(height: 32),

            _DetailRow(
              label: 'Registrado por',
              value: expense.userName ?? 'Desconocido',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
