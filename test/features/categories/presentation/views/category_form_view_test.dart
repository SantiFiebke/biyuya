import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/categories/presentation/views/category_form_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

final _testCategory = Category(
  id: 42,
  name: 'Food',
  householdId: 1,
  createdAt: DateTime(2025),
  color: '#4CAF50',
  icon: '63046',
);

/// Records submit args; returns false so the view skips `context.pop()`
/// (no GoRouter in the test wrapper).
class FakeCategoryController extends CategoryController {
  int submitCount = 0;
  String? lastName;
  double? lastBudgetAmount;
  bool? lastIsExpense;

  @override
  AsyncValue<List<Category>> build() => const AsyncData([]);

  @override
  Future<bool> submitCategory({
    required String name,
    String? color,
    String? icon,
    double? budgetAmount,
    int? categoryId,
    bool isExpense = true,
  }) async {
    submitCount++;
    lastName = name;
    lastBudgetAmount = budgetAmount;
    lastIsExpense = isExpense;
    return false;
  }
}

List<Override> _withFake(FakeCategoryController fake) => [
  categoryControllerProvider.overrideWith(() => fake),
];

void main() {
  group('CategoryFormView', () {
    testWidgets('renders create mode with correct title and button', (
      tester,
    ) async {
      await tester.pumpWidget(wrapTest(child: const CategoryFormView()));
      await tester.pumpAndSettle();

      expect(find.text('Nueva categoría'), findsOneWidget);
      expect(find.text('Crear'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('renders edit mode with correct title and button', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(child: CategoryFormView(category: _testCategory)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Editar categoría'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('pre-fills name in edit mode', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: CategoryFormView(category: _testCategory)),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(field.controller?.text, 'Food');
    });

    testWidgets('shows validation error for empty name', (tester) async {
      await tester.pumpWidget(wrapTest(child: const CategoryFormView()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Crear'));
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresá un nombre'), findsOneWidget);
    });

    testWidgets('shows validation error for name shorter than 2 chars', (
      tester,
    ) async {
      await tester.pumpWidget(wrapTest(child: const CategoryFormView()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'A');
      await tester.ensureVisible(find.text('Crear'));
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(find.text('Mínimo 2 caracteres'), findsOneWidget);
    });

    testWidgets('shows color picker section', (tester) async {
      await tester.pumpWidget(wrapTest(child: const CategoryFormView()));
      await tester.pumpAndSettle();

      expect(find.text('Color'), findsOneWidget);
      expect(find.byType(ColorPickerRow), findsOneWidget);
    });

    testWidgets('shows icon picker grid', (tester) async {
      await tester.pumpWidget(wrapTest(child: const CategoryFormView()));
      await tester.pumpAndSettle();

      expect(find.text('Ícono'), findsOneWidget);
      expect(find.byType(IconPickerGrid), findsOneWidget);
    });

    testWidgets('shows saved icon outside preset set as selected in grid', (
      tester,
    ) async {
      final category = Category(
        id: 42,
        name: 'Salud',
        householdId: 1,
        createdAt: DateTime(2025),
        color: '#4CAF50',
        icon: Icons.local_hospital.codePoint.toString(),
      );

      await tester.pumpWidget(
        wrapTest(child: CategoryFormView(category: category)),
      );
      await tester.pumpAndSettle();

      // Icon fuera del set curado se agrega al final: scrollear hasta él.
      await tester.scrollUntilVisible(
        find.byIcon(Icons.local_hospital),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byType(IconPickerGrid)));

      final outsideIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(IconPickerGrid),
          matching: find.byIcon(Icons.local_hospital),
        ),
      );
      expect(outsideIcon.color, theme.colorScheme.primary);

      // Fallback Icons.category NO queda seleccionado.
      final fallbackIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(IconPickerGrid),
          matching: find.byIcon(Icons.category),
        ),
      );
      expect(fallbackIcon.color, isNot(theme.colorScheme.primary));
    });

    testWidgets('no validation error with valid name', (tester) async {
      await tester.pumpWidget(wrapTest(child: const CategoryFormView()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Groceries');
      await tester.pumpAndSettle();

      expect(find.text('Ingresá un nombre'), findsNothing);
      expect(find.text('Mínimo 2 caracteres'), findsNothing);
    });

    testWidgets('renders Límite mensual field', (tester) async {
      await tester.pumpWidget(wrapTest(child: const CategoryFormView()));
      await tester.pumpAndSettle();

      expect(find.text('Límite mensual (ARS)'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('budget field formats thousands live', (tester) async {
      await tester.pumpWidget(wrapTest(child: const CategoryFormView()));
      await tester.pumpAndSettle();

      final budgetField = find.byType(TextFormField).at(1);

      await tester.enterText(budgetField, '1500');
      await tester.pump();
      expect(
        tester.widget<TextFormField>(budgetField).controller?.text,
        '1.500',
      );

      await tester.enterText(budgetField, '1234,56');
      await tester.pump();
      expect(
        tester.widget<TextFormField>(budgetField).controller?.text,
        '1.234,56',
      );
    });

    testWidgets('pre-fills formatted budget in edit mode', (tester) async {
      final category = Category(
        id: 42,
        name: 'Food',
        householdId: 1,
        createdAt: DateTime(2025),
        color: '#4CAF50',
        icon: '63046',
        budgetAmount: 1500.5,
      );

      await tester.pumpWidget(
        wrapTest(child: CategoryFormView(category: category)),
      );
      await tester.pumpAndSettle();

      final budgetField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );
      expect(budgetField.controller?.text, '1.500,50');
    });

    testWidgets('submits parsed budgetAmount from valid value', (tester) async {
      final fake = FakeCategoryController();
      await tester.pumpWidget(
        wrapTest(child: const CategoryFormView(), overrides: _withFake(fake)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Food');
      await tester.enterText(find.byType(TextFormField).at(1), '1500,50');
      await tester.ensureVisible(find.text('Crear'));
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(fake.submitCount, 1);
      expect(fake.lastName, 'Food');
      expect(fake.lastBudgetAmount, 1500.5);
    });

    testWidgets('submits null budgetAmount when field empty', (tester) async {
      final fake = FakeCategoryController();
      await tester.pumpWidget(
        wrapTest(child: const CategoryFormView(), overrides: _withFake(fake)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Food');
      await tester.ensureVisible(find.text('Crear'));
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(fake.submitCount, 1);
      expect(fake.lastBudgetAmount, isNull);
    });

    testWidgets('shows error and does not submit for zero budget', (
      tester,
    ) async {
      final fake = FakeCategoryController();
      await tester.pumpWidget(
        wrapTest(child: const CategoryFormView(), overrides: _withFake(fake)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Food');
      await tester.enterText(find.byType(TextFormField).at(1), '0');
      await tester.ensureVisible(find.text('Crear'));
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(find.text('El monto debe ser mayor a 0'), findsOneWidget);
      expect(fake.submitCount, 0);
    });

    testWidgets('switch "Cuenta como gasto" defaults ON for new category', (
      tester,
    ) async {
      await tester.pumpWidget(wrapTest(child: const CategoryFormView()));
      await tester.pumpAndSettle();

      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(find.text('Cuenta como gasto'), findsOneWidget);
      expect(tile.value, isTrue);
    });

    testWidgets(
      'switch starts OFF when editing category with isExpense false',
      (tester) async {
        final category = Category(
          id: 42,
          name: 'Ahorro',
          householdId: 1,
          createdAt: DateTime(2025),
          color: '#4CAF50',
          icon: '63046',
          isExpense: false,
        );

        await tester.pumpWidget(
          wrapTest(child: CategoryFormView(category: category)),
        );
        await tester.pumpAndSettle();

        final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
        expect(tile.value, isFalse);
      },
    );

    testWidgets('toggling switch off and submitting passes isExpense=false', (
      tester,
    ) async {
      final fake = FakeCategoryController();
      await tester.pumpWidget(
        wrapTest(child: const CategoryFormView(), overrides: _withFake(fake)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Ahorro');
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );

      await tester.ensureVisible(find.text('Crear'));
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(fake.submitCount, 1);
      expect(fake.lastIsExpense, isFalse);
    });

    testWidgets('submitting without toggling passes isExpense=true', (
      tester,
    ) async {
      final fake = FakeCategoryController();
      await tester.pumpWidget(
        wrapTest(child: const CategoryFormView(), overrides: _withFake(fake)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Food');
      await tester.ensureVisible(find.text('Crear'));
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(fake.submitCount, 1);
      expect(fake.lastIsExpense, isTrue);
    });

    testWidgets('info icon opens info dialog with explanation', (tester) async {
      await tester.pumpWidget(wrapTest(child: const CategoryFormView()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.info_outline));
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text('¿Qué significa "Cuenta como gasto"?'), findsOneWidget);
      expect(
        find.text(
          'Si lo desactivás, los gastos de esta categoría no se suman a los '
          'totales ni a los reportes (por ejemplo, Ahorro). Seguís viendo los '
          'movimientos en la lista de gastos.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);
    });
  });
}
