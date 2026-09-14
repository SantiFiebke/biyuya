import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _presetColors = [
  '#F44336',
  '#E91E63',
  '#9C27B0',
  '#673AB7',
  '#3F51B5',
  '#2196F3',
  '#4CAF50',
  '#FF9800',
  '#795548',
  '#607D8B',
];

/// Shows a modal bottom sheet for creating a new category.
/// Returns the new category's ID if created, null otherwise.
Future<int?> showCreateCategorySheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final nameController = TextEditingController();
  String? selectedColor;
  int? newCategoryId;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nueva categoría',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _presetColors.map((hex) {
                final color = Color(
                  int.parse('FF${hex.substring(1)}', radix: 16),
                );
                return GestureDetector(
                  onTap: () => setSheetState(() => selectedColor = hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selectedColor == hex
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  return;
                }

                final success = await ref
                    .read(categoryControllerProvider.notifier)
                    .createCategory(
                      name: nameController.text.trim(),
                      color: selectedColor,
                    );

                if (success && context.mounted) {
                  Navigator.pop(context);
                  final categories =
                      ref.read(categoryControllerProvider).value ?? [];
                  if (categories.isNotEmpty) {
                    newCategoryId = categories.last.id;
                  }
                }
              },
              child: const Text('Crear'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );

  return newCategoryId;
}
