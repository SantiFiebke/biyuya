import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class CategoryDropdown extends ConsumerWidget {
  const CategoryDropdown({
    required this.selectedCategoryId,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final int? selectedCategoryId;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCategories = ref.watch(categoryControllerProvider);

    return asyncCategories.when(
      loading: () => DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Categoría',
          prefixIcon: Icon(Icons.category_outlined),
        ),
        items: const [],
        disabledHint: const Text('Cargando categorías...'),
        onChanged: null,
      ),
      error: (_, _) => DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Categoría',
          prefixIcon: Icon(Icons.category_outlined),
        ),
        items: const [],
        disabledHint: const Text('Error al cargar categorías'),
        onChanged: null,
      ),
      data: (categories) => DropdownButtonFormField<int>(
        initialValue: selectedCategoryId,
        decoration: const InputDecoration(
          labelText: 'Categoría',
          prefixIcon: Icon(Icons.category_outlined),
        ),
        items: [
          ...categories.map(_buildItem),
          const DropdownMenuItem<int>(
            value: -1,
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, size: 20),
                SizedBox(width: 8),
                Text('Crear nueva categoría'),
              ],
            ),
          ),
        ],
        onChanged: enabled ? onChanged : null,
        validator: (value) {
          if (value == null || value == -1) {
            return 'Elegí una categoría';
          }
          return null;
        },
      ),
    );
  }

  DropdownMenuItem<int> _buildItem(Category category) {
    final color = parseCategoryColor(category.color);
    final icon = iconFromCodePoint(category.icon);

    return DropdownMenuItem(
      value: category.id,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: (color ?? Colors.grey).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color ?? Colors.grey),
          ),
          const SizedBox(width: 12),
          Text(category.name),
        ],
      ),
    );
  }
}
