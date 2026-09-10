import 'package:biyuya/src/features/auth/presentation/presentation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(authSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas claras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Próximamente')));
            },
          ),
        ],
      ),
      body: userProfile.when(
        data: (profile) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HomeWelcomeCard(
                  name: profile?.name ?? '',
                  householdId: profile?.householdId ?? '',
                ),
                const SizedBox(height: 24),
                const HomeEmptyState(),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Próximamente')));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class HomeWelcomeCard extends StatelessWidget {
  const HomeWelcomeCard({
    required this.name,
    required this.householdId,
    super.key,
  });

  final String name;
  final String householdId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Hola, $name',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Hogar: $householdId',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Los gastos aparecerán acá',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Gestionar categorías'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/categories'),
            ),
          ],
        ),
      ),
    );
  }
}
