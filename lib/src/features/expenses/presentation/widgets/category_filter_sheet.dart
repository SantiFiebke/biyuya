import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows a modal bottom sheet with category list.
/// Calls [onSelected] with selected category id, or null for "all".
Future<void> showCategoryFilterSheet(
  BuildContext context,
  WidgetRef ref, {
  ValueChanged<int?>? onSelected,
}) async {
  final categories = ref.read(categoryControllerProvider).value ?? [];

  await showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Todas las categorías'),
            onTap: () {
              onSelected?.call(null);
              Navigator.pop(context);
            },
          ),
          ...categories.map(
            (category) => ListTile(
              title: Text(category.name),
              leading: Icon(
                Icons.circle,
                color: parseCategoryColor(category.color),
              ),
              onTap: () {
                onSelected?.call(category.id);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    ),
  );
}
