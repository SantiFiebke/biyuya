import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

class ExpenseFormView extends ConsumerStatefulWidget {
  const ExpenseFormView({super.key, this.expense});

  final Expense? expense;

  @override
  ConsumerState<ExpenseFormView> createState() => _ExpenseFormViewState();
}

class _ExpenseFormViewState extends ConsumerState<ExpenseFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  int? _selectedCategoryId;
  late DateTime _selectedDate;
  bool _saving = false;

  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _amountController = TextEditingController(
      text: expense?.amount.toStringAsFixed(2) ?? '',
    );
    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );
    _selectedCategoryId = expense?.categoryId;
    _selectedDate = expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _formattedDate => DateFormat('dd/MM/yyyy').format(_selectedDate);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'AR'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _showCreateCategorySheet() async {
    final nameController = TextEditingController();
    String? selectedColor;

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
              // Color picker
              Wrap(
                spacing: 8,
                children:
                    [
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
                    ].map((hex) {
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
                    // Auto-select the newly created category
                    final newCategories =
                        ref.read(categoryControllerProvider).value ?? [];
                    if (newCategories.isNotEmpty) {
                      setState(
                        () => _selectedCategoryId = newCategories.last.id,
                      );
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
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      context.showErrorSnackBar('Elegí una categoría');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      context.showErrorSnackBar('Ingresá un monto válido');
      return;
    }

    setState(() => _saving = true);

    final description = _descriptionController.text.trim();
    bool success;

    if (isEditing) {
      success = await ref
          .read(expenseControllerProvider.notifier)
          .updateExpense(
            id: widget.expense!.id,
            amount: amount,
            date: _selectedDate,
            description: description.isEmpty ? null : description,
            categoryId: _selectedCategoryId!,
          );
    } else {
      success = await ref
          .read(expenseControllerProvider.notifier)
          .createExpense(
            amount: amount,
            date: _selectedDate,
            description: description.isEmpty ? null : description,
            categoryId: _selectedCategoryId!,
          );
    }

    if (!mounted) {
      return;
    }
    setState(() => _saving = false);

    if (success) {
      context
        ..showSuccessSnackBar(isEditing ? 'Gasto actualizado' : 'Gasto creado')
        ..pop();
    } else {
      context.showErrorSnackBar('Error al guardar el gasto');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar gasto' : 'Nuevo gasto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: r'\$ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                enabled: !_saving,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresá un monto';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _CategoryDropdown(
                selectedCategoryId: _selectedCategoryId,
                enabled: !_saving,
                onChanged: (id) async {
                  if (id == -1) {
                    await _showCreateCategorySheet();
                  } else {
                    setState(() => _selectedCategoryId = id);
                  }
                },
              ),
              const SizedBox(height: 24),
              _DateField(
                formattedDate: _formattedDate,
                enabled: !_saving,
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                enabled: !_saving,
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
                    : const Text('Guardar'),
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

class _CategoryDropdown extends ConsumerWidget {
  const _CategoryDropdown({
    required this.selectedCategoryId,
    required this.enabled,
    required this.onChanged,
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
    final color = _parseColor(category.color);
    final icon = _iconFromCodePoint(category.icon);

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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.formattedDate,
    required this.enabled,
    required this.onTap,
  });

  final String formattedDate;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Fecha',
        prefixIcon: Icon(Icons.calendar_today),
      ),
      controller: TextEditingController(text: formattedDate),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }
}
