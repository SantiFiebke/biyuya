import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
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
                onEdit: () => context.push('/categories/edit/${category.id}'),
                onDelete: () => _confirmDelete(context, ref, category),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/categories/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Estás segura de que querés eliminar "${category.name}"?',
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

  @override
  Widget build(BuildContext context) {
    final color =
        _parseColor(category.color) ?? Theme.of(context).colorScheme.primary;

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
          child: Icon(
            _iconFromCodePoint(category.icon),
            color: color,
            size: 20,
          ),
        ),
        title: Text(category.name),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
      ),
    );
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
