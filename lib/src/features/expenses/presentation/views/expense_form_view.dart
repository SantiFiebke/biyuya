import 'package:biyuya/src/core/models/expense_deep_link_params.dart';
import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/widgets/category_dropdown.dart';
import 'package:biyuya/src/features/expenses/presentation/widgets/create_category_bottom_sheet.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

class ExpenseFormView extends ConsumerStatefulWidget {
  const ExpenseFormView({super.key, this.expense, this.deepLinkParams});

  final Expense? expense;
  final ExpenseDeepLinkParams? deepLinkParams;

  @override
  ConsumerState<ExpenseFormView> createState() => _ExpenseFormViewState();
}

class _ExpenseFormViewState extends ConsumerState<ExpenseFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  int? _selectedCategoryId;

  bool get isEditing => widget.expense != null;

  bool get _isAutoSubmitMode =>
      widget.deepLinkParams?.autoSubmit == true &&
      widget.deepLinkParams?.amount != null;

  bool get _saving => ref.watch(expenseControllerProvider).isLoading;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    final deepLink = widget.deepLinkParams;

    _amountController = TextEditingController(
      text:
          expense?.amount.toStringAsFixed(2) ??
          deepLink?.amount?.toStringAsFixed(2) ??
          '',
    );
    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );
    _selectedCategoryId = expense?.categoryId ?? deepLink?.categoryId;
    _selectedDate = expense?.date ?? DateTime.now();

    if (_isAutoSubmitMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoSubmit());
    }
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

    final description = _descriptionController.text.trim();
    final success = await ref
        .read(expenseControllerProvider.notifier)
        .submitExpense(
          amount: amount,
          description: description.isEmpty ? null : description,
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          expenseId: widget.expense?.id,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      context
        ..showSuccessSnackBar(isEditing ? 'Gasto actualizado' : 'Gasto creado')
        ..go(AppRoute.home.path);
    } else {
      context.showErrorSnackBar('Error al guardar el gasto');
    }
  }

  Future<void> _autoSubmit() async {
    if (!mounted) {
      return;
    }
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

    final description = _descriptionController.text.trim();
    final success = await ref
        .read(expenseControllerProvider.notifier)
        .submitExpense(
          amount: amount,
          description: description.isEmpty ? null : description,
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          expenseId: widget.expense?.id,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      context
        ..showSuccessSnackBar('Gasto registrado')
        ..go(AppRoute.home.path);
    } else {
      context.showErrorSnackBar('Error al registrar el gasto');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isAutoSubmitMode && _saving
              ? 'Registrando gasto...'
              : isEditing
              ? 'Editar gasto'
              : 'Nuevo gasto',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoute.home.path),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                  CategoryDropdown(
                    selectedCategoryId: _selectedCategoryId,
                    enabled: !_saving,
                    onChanged: (id) async {
                      if (id == -1) {
                        final newId = await showCreateCategorySheet(
                          context,
                          ref,
                        );
                        if (newId != null) {
                          setState(() => _selectedCategoryId = newId);
                        }
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
                    onPressed: _saving ? null : () => context.go(AppRoute.home.path),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
          if (_isAutoSubmitMode && _saving)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
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
