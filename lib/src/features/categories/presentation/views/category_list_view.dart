import 'package:biyuya/src/core/presentation/dialogs/confirm_action_dialog.dart';
import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CategoryListView extends ConsumerWidget {
  const CategoryListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCategories = ref.watch(categoryControllerProvider);

    ref.listen<AsyncValue<List<Category>>>(categoryControllerProvider, (
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
      appBar: AppBar(title: const Text('Categorías')),
      body: asyncCategories.when(
        loading: () => const _CategorySkeleton(),
        error: (error, _) => Center(
          child: Text(
            'Error al cargar categorías',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyCategories();
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryTile(
                category: category,
                onEdit: () => context.push(
                  AppRoute.categoryEdit(category.id.toString()),
                  extra: category,
                ),
                onDelete: () => _confirmDelete(context, ref, category),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => context.push(AppRoute.categoryNew.path),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: 'Eliminar categoría',
      content: '¿Estás segura de que querés eliminar "${category.name}"?',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );
    if (confirmed) {
      await ref
          .read(categoryControllerProvider.notifier)
          .deleteCategory(id: category.id);
    }
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color =
        parseCategoryColor(category.color) ??
        Theme.of(context).colorScheme.primary;

    return Dismissible(
      key: ValueKey(category.id),
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
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(iconFromCodePoint(category.icon), color: color, size: 20),
        ),
        title: Text(category.name),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

class EmptyCategories extends StatelessWidget {
  const EmptyCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay categorías',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Creá una para empezar.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

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
          trailing: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}
