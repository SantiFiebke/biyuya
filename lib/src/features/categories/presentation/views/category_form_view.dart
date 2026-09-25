import 'package:biyuya/src/core/presentation/dialogs/info_dialog.dart';
import 'package:biyuya/src/core/presentation/extensions/context_extensions.dart';
import 'package:biyuya/src/core/presentation/utils/category_utils.dart';
import 'package:biyuya/src/core/presentation/utils/form_validators.dart';
import 'package:biyuya/src/core/presentation/widgets/color_picker_row.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

export 'package:biyuya/src/core/presentation/widgets/color_picker_row.dart'
    show ColorPickerRow;

const _presetIcons = <IconData>[
  Icons.shopping_cart, // supermercado
  Icons.shopping_bag, // compras
  Icons.restaurant, // salidas / delivery
  Icons.directions_bus, // transporte
  Icons.directions_car, // auto
  Icons.local_gas_station, // combustible
  Icons.home, // casa
  Icons.build, // arreglos / reparaciones
  Icons.medical_services, // salud
  Icons.school, // educación
  Icons.fitness_center, // gym
  Icons.spa, // cuidado personal
  Icons.pets, // mascotas
  Icons.child_friendly, // bebé
  Icons.volunteer_activism, // ayudas
  Icons.card_giftcard, // regalos
  Icons.checkroom, // ropa / calzado
  Icons.credit_card, // tarjetas / préstamos
  Icons.receipt_long, // servicios
  Icons.bolt, // servicios (utilities)
  Icons.phone_android, // telefonía
  Icons.wifi, // internet
  Icons.music_note, // ocio
  Icons.sports_esports, // juegos
  Icons.movie, // entretenimiento
  Icons.flight, // viajes
  Icons.savings, // ahorro
  Icons.work, // trabajo
  Icons.category, // otros
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
  late final TextEditingController _budgetController;
  String? _selectedColor;
  IconData? _selectedIcon;
  late bool _isExpense;

  bool get _saving => ref.watch(categoryControllerProvider).isLoading;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _budgetController = TextEditingController(
      text: cat?.budgetAmount == null
          ? ''
          : FormValidators.formatAmountInput(cat!.budgetAmount!),
    );
    _isExpense = cat?.isExpense ?? true;
    _selectedColor = cat?.color;
    _selectedIcon = cat?.icon != null
        ? _presetIcons.firstWhere(
            (e) => e.codePoint.toString() == cat!.icon,
            orElse: () => iconFromCodePoint(cat!.icon),
          )
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final iconCode = _selectedIcon?.codePoint.toString();
    final categoryId = widget.category?.id;
    final budgetAmount = FormValidators.parseAmount(_budgetController.text);

    final success = await ref
        .read(categoryControllerProvider.notifier)
        .submitCategory(
          name: name,
          color: _selectedColor,
          icon: iconCode,
          budgetAmount: budgetAmount,
          categoryId: categoryId,
          isExpense: _isExpense,
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
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Límite mensual (ARS)',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [CurrencyTextInputFormatter()],
                enabled: !_saving,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  final parsed = FormValidators.parseAmount(value);
                  if (parsed == null) {
                    return 'Ingresá un monto válido';
                  }
                  if (parsed <= 0) {
                    return 'El monto debe ser mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                secondary: const Icon(Icons.receipt_long_outlined),
                title: Row(
                  children: [
                    const Expanded(child: Text('Cuenta como gasto')),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => showInfoDialog(
                        context: context,
                        title: '¿Qué significa "Cuenta como gasto"?',
                        content:
                            'Si lo desactivás, los gastos de esta categoría no se suman a los totales ni a los reportes (por ejemplo, Ahorro). Seguís viendo los movimientos en la lista de gastos.',
                      ),
                    ),
                  ],
                ),
                subtitle: const Text('Se suma a los totales y reportes'),
                value: _isExpense,
                onChanged: (value) => setState(() => _isExpense = value),
              ),
              const SizedBox(height: 24),
              Text('Color', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ColorPickerRow(
                colors: presetCategoryColors
                    .map(parseCategoryColor)
                    .whereType<Color>()
                    .toList(),
                selectedColor: parseCategoryColor(_selectedColor),
                onSelected: (color) {
                  final hex = presetCategoryColors.firstWhere(
                    (h) => parseCategoryColor(h) == color,
                  );
                  setState(
                    () => _selectedColor =
                        parseCategoryColor(_selectedColor) == color
                        ? null
                        : hex,
                  );
                },
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

class IconPickerGrid extends StatefulWidget {
  const IconPickerGrid({
    required this.selectedIcon,
    required this.onIconSelected,
    super.key,
  });

  final IconData? selectedIcon;
  final ValueChanged<IconData?> onIconSelected;

  @override
  State<IconPickerGrid> createState() => _IconPickerGridState();
}

class _IconPickerGridState extends State<IconPickerGrid> {
  static const int _perPage = 8; // 2 filas × 4 columnas
  static const double _spacing = 8;

  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    final selected = widget.selectedIcon;
    final index = selected == null ? -1 : _icons.indexOf(selected);
    _page = index >= 0 ? index ~/ _perPage : 0;
    _pageController = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Icono guardado fuera del set curado (hogares viejos) se agrega al final
  // para que siga viéndose seleccionado.
  List<IconData> get _icons => <IconData>[
    ..._presetIcons,
    if (widget.selectedIcon != null &&
        !_presetIcons.contains(widget.selectedIcon))
      widget.selectedIcon!,
  ];

  @override
  Widget build(BuildContext context) {
    final icons = _icons;
    final pages = (icons.length / _perPage).ceil();
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ícono', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tile = (constraints.maxWidth - 3 * _spacing) / 4;
            final pageHeight = tile * 2 + _spacing;
            return SizedBox(
              height: pageHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, page) {
                  final start = page * _perPage;
                  final end = (start + _perPage).clamp(0, icons.length);
                  final pageIcons = icons.sublist(start, end);
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: _spacing,
                          crossAxisSpacing: _spacing,
                        ),
                    itemCount: pageIcons.length,
                    itemBuilder: (context, index) {
                      final icon = pageIcons[index];
                      final isSelected = widget.selectedIcon == icon;
                      return _IconTile(
                        icon: icon,
                        isSelected: isSelected,
                        onTap: () =>
                            widget.onIconSelected(isSelected ? null : icon),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
        if (pages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 10 : 8,
                  height: active ? 10 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                );
              }),
            ),
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
