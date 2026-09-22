import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/core/presentation/utils/form_validators.dart';
import 'package:biyuya/src/core/presentation/widgets/color_picker_row.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Shows a modal bottom sheet for creating a new category.
/// Returns the new category's ID if created, null otherwise.
Future<int?> showCreateCategorySheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final nameController = TextEditingController();
  String? selectedColor;
  int? newCategoryId;

  final formKey = GlobalKey<FormState>();

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
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nueva categoría',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                maxLength: FormValidators.categoryNameMaxLength,
                validator: FormValidators.categoryName,
              ),
              const SizedBox(height: 16),
              ColorPickerRow(
                colors: presetCategoryColors
                    .map(parseCategoryColor)
                    .whereType<Color>()
                    .toList(),
                selectedColor: parseCategoryColor(selectedColor),
                onSelected: (color) {
                  final hex = presetCategoryColors.firstWhere(
                    (h) => parseCategoryColor(h) == color,
                  );
                  setSheetState(() => selectedColor = hex);
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('Crear'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );

  return newCategoryId;
}
