import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/core/presentation/utils/form_validators.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

const _presetIcons = <IconData>[
  Icons.shopping_cart,
  Icons.restaurant,
  Icons.directions_bus,
  Icons.home,
  Icons.local_hospital,
  Icons.school,
  Icons.fitness_center,
  Icons.pets,
  Icons.child_care,
  Icons.drive_eta,
  Icons.music_note,
  Icons.sports_esports,
  Icons.checkroom,
  Icons.local_grocery_store,
  Icons.local_cafe,
  Icons.payments,
];

class CategoryFormView extends ConsumerStatefulWidget {
  const CategoryFormView({super.key, this.category});

  final Category? category;

  @override
  ConsumerState<CategoryFormView> createState() => _CategoryFormViewState();
}

class _CategoryFormViewState extends ConsumerState<CategoryFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _selectedColor;
  IconData? _selectedIcon;

  bool get _saving => ref.watch(categoryControllerProvider).isLoading;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _selectedColor = cat?.color;
    _selectedIcon = cat?.icon != null
        ? _presetIcons.firstWhere(
            (e) => e.codePoint.toString() == cat!.icon,
            orElse: () => Icons.category,
          )
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final iconCode = _selectedIcon?.codePoint.toString();
    final categoryId = widget.category?.id;

    final success = await ref
        .read(categoryControllerProvider.notifier)
        .submitCategory(
          name: name,
          color: _selectedColor,
          icon: iconCode,
          categoryId: categoryId,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      context
        ..showSuccessSnackBar(
          isEditing ? 'Categoría actualizada' : 'Categoría creada',
        )
        ..pop();
    } else {
      context.showErrorSnackBar('Error al guardar la categoría');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar categoría' : 'Nueva categoría'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.words,
                enabled: !_saving,
                maxLength: FormValidators.categoryNameMaxLength,
                validator: FormValidators.categoryName,
              ),
              const SizedBox(height: 24),
              ColorPickerRow(
                selectedColor: _selectedColor,
                onColorSelected: (color) =>
                    setState(() => _selectedColor = color),
              ),
              const SizedBox(height: 24),
              IconPickerGrid(
                selectedIcon: _selectedIcon,
                onIconSelected: (icon) => setState(() => _selectedIcon = icon),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Guardar' : 'Crear'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _saving ? null : () => context.pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    required this.selectedColor,
    required this.onColorSelected,
    super.key,
  });

  final String? selectedColor;
  final ValueChanged<String?> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final parsedSelected = parseCategoryColor(selectedColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final hex in _presetColors)
              _ColorCircle(
                color: parseCategoryColor(hex)!,
                isSelected: parsedSelected == parseCategoryColor(hex),
                onTap: () => onColorSelected(
                  parsedSelected == parseCategoryColor(hex) ? null : hex,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 3,
                )
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

class IconPickerGrid extends StatelessWidget {
  const IconPickerGrid({
    required this.selectedIcon,
    required this.onIconSelected,
    super.key,
  });

  final IconData? selectedIcon;
  final ValueChanged<IconData?> onIconSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ícono', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _presetIcons.length,
          itemBuilder: (context, index) {
            final icon = _presetIcons[index];
            final isSelected = selectedIcon == icon;
            return _IconTile(
              icon: icon,
              isSelected: isSelected,
              onTap: () => onIconSelected(isSelected ? null : icon),
            );
          },
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
