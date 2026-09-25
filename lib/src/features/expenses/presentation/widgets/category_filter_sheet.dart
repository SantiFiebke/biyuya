import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/core/presentation/widgets/category_avatar.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Shows a modal bottom sheet with category list.
/// Calls [onSelected] with selected category id, or null for "all".
Future<void> showCategoryFilterSheet(
  BuildContext context,
  WidgetRef ref, {
  ValueChanged<int?>? onSelected,
  int? selectedCategoryId,
}) async {
  final categories = ref.read(categoryControllerProvider).value ?? [];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) => DraggableScrollableSheet(
      // Explicit to pin sheet sizing intent; matches framework default.
      // ignore: avoid_redundant_argument_values
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Column(
          children: [
            const _SheetHeader(),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: categories.length + 1,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _FilterRow(
                      avatar: const CategoryAvatar(icon: Icons.apps),
                      title: 'Todas las categorías',
                      selected: selectedCategoryId == null,
                      onTap: () {
                        onSelected?.call(null);
                        Navigator.pop(context);
                      },
                    );
                  }
                  final category = categories[index - 1];
                  return _FilterRow(
                    avatar: CategoryAvatar(
                      icon: iconFromCodePoint(category.icon),
                      color: parseCategoryColor(category.color),
                    ),
                    title: category.name,
                    selected: category.id == selectedCategoryId,
                    onTap: () {
                      onSelected?.call(category.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Drag handle + title + close button.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Filtrar por categoría',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// Single selectable row: avatar, title, trailing check.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.avatar,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final Widget avatar;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: avatar,
      title: Text(title),
      trailing: selected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
