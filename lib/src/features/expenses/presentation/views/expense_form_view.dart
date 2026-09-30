import 'dart:async';

import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/core/presentation/utils/date_utils.dart';
import 'package:biyuya/src/core/presentation/utils/form_validators.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/widgets/category_dropdown.dart';
import 'package:biyuya/src/features/expenses/presentation/widgets/create_category_bottom_sheet.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class ExpenseFormView extends ConsumerStatefulWidget {
  const ExpenseFormView({super.key, this.expense, this.initialCategoryId});

  final Expense? expense;

  /// Categoría a prefillear cuando se llega por deep link (`?categoryId=`).
  final int? initialCategoryId;

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

  bool get _saving => ref.watch(expenseControllerProvider).isLoading;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;

    _amountController = TextEditingController(
      text: expense == null
          ? ''
          : FormValidators.formatAmountInput(expense.amount),
    );
    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );
    _selectedCategoryId = expense?.categoryId ?? widget.initialCategoryId;
    _selectedDate = expense?.date ?? DateTime.now();
  }

  @override
  void didUpdateWidget(covariant ExpenseFormView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId) {
      setState(() {
        _selectedCategoryId =
            widget.expense?.categoryId ?? widget.initialCategoryId;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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

  /// Cierra el form: `pop` si hay ruta empujada en el branch de Expenses
  /// (evita que `go(home)` deje el form en el stack del shell branch).
  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoute.home.path);
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

    final amount = FormValidators.parseAmount(_amountController.text);
    if (amount == null) {
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
      context.showSuccessSnackBar(
        isEditing ? 'Gasto actualizado' : 'Gasto creado',
      );
      _close();
    } else {
      context.showErrorSnackBar('Error al guardar el gasto');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Clear a stale selection (e.g. deep-link categoryId that no longer
    // exists) once categories finish loading. Registered in build, not
    // initState, so the first frame is not lost.
    ref.listen<AsyncValue<List<Category>>>(categoryControllerProvider, (
      previous,
      next,
    ) {
      final categories = next.value;
      final selected = _selectedCategoryId;
      if (categories == null || selected == null) {
        return;
      }
      if (categories.any((category) => category.id == selected)) {
        return;
      }
      setState(() => _selectedCategoryId = null);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar gasto' : 'Nuevo gasto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _close,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero: monto centrado ──
              _AmountHero(controller: _amountController, saving: _saving),
              const SizedBox(height: 12),

              // ── Categoría ──
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: CategoryDropdown(
                    selectedCategoryId: _selectedCategoryId,
                    enabled: !_saving,
                    onChanged: (id) async {
                      if (id != -1) {
                        setState(() => _selectedCategoryId = id);
                        return;
                      }
                      final newId = await showCreateCategorySheet(context, ref);
                      setState(() => _selectedCategoryId = newId);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Fecha ──
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: _DateField(
                    formattedDate: formatHumanDate(_selectedDate),
                    enabled: !_saving,
                    onTap: _pickDate,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Descripción ──
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción (opcional)',
                      hintText: 'Ej: Compra en el supermercado, etc.',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    maxLines: 3,
                    maxLength: FormValidators.descriptionMaxLength,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_saving,
                    validator: FormValidators.description,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── CTA ──
              ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        unawaited(HapticFeedback.mediumImpact());
                        await _submit();
                      },
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar gasto'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _saving ? null : _close,
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets extraídos (dumb, StatelessWidget)
// ---------------------------------------------------------------------------

/// Sección hero: monto grande centrado con prefijo `$`.
class _AmountHero extends StatelessWidget {
  const _AmountHero({required this.controller, required this.saving});

  final TextEditingController controller;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            Text(
              'Monto',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.attach_money),
                hintText: '0,00',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                errorMaxLines: 2,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [CurrencyTextInputFormatter()],
              autofocus: true,
              enabled: !saving,
              validator: FormValidators.amount,
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de fecha con display humanizado.
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
      initialValue: formattedDate,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Fecha',
        prefixIcon: Icon(Icons.calendar_today),
      ),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }
}
