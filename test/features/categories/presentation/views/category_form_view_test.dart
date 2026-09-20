import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/views/category_form_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_helpers.dart';

final _testCategory = Category(
  id: 42,
  name: 'Food',
  householdId: 1,
  createdAt: DateTime(2025),
  color: '#4CAF50',
  icon: '63046',
);

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

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
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

      await tester.enterText(find.byType(TextFormField), 'A');
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

    testWidgets('no validation error with valid name', (tester) async {
      await tester.pumpWidget(wrapTest(child: const CategoryFormView()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Groceries');
      await tester.pumpAndSettle();

      expect(find.text('Ingresá un nombre'), findsNothing);
      expect(find.text('Mínimo 2 caracteres'), findsNothing);
    });
  });
}
