import 'dart:async';

import 'package:biyuya/src/core/presentation/dialogs/confirm_action_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_helpers.dart';

Future<void> _openDialog(WidgetTester tester) async {
  await tester.pumpWidget(
    wrapTest(
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => unawaited(
            showConfirmActionDialog(
              context: context,
              title: 'Eliminar gasto',
              content: '¿Estás segura de que querés eliminar este gasto?',
              confirmLabel: 'Eliminar',
              isDestructive: true,
            ),
          ),
          child: const Text('Abrir'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  group('showConfirmActionDialog', () {
    testWidgets('renders title, content and action labels', (tester) async {
      await _openDialog(tester);

      expect(find.text('Eliminar gasto'), findsOneWidget);
      expect(
        find.text('¿Estás segura de que querés eliminar este gasto?'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Eliminar'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancelar'), findsOneWidget);
    });

    testWidgets('content Text uses bodyLarge style', (tester) async {
      await _openDialog(tester);

      final content = tester.widget<Text>(
        find.text('¿Estás segura de que querés eliminar este gasto?'),
      );
      final theme = Theme.of(
        tester.element(
          find.text('¿Estás segura de que querés eliminar este gasto?'),
        ),
      );

      expect(content.style, isNotNull);
      expect(content.style!.fontSize, theme.textTheme.bodyLarge!.fontSize);
      expect(content.style!.fontSize, 16);
    });

    testWidgets('cancel returns false and confirm returns true', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        wrapTest(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => result = await showConfirmActionDialog(
                context: context,
                title: 'Título',
                content: 'Contenido',
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();
      expect(result, isFalse);

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Confirmar'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });
}
