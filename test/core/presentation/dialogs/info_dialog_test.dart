import 'dart:async';

import 'package:biyuya/src/core/presentation/dialogs/info_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_helpers.dart';

Future<void> _openDialog(WidgetTester tester) async {
  await tester.pumpWidget(
    wrapTest(
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => unawaited(
            showInfoDialog(
              context: context,
              title: '¿Qué significa "Cuenta como gasto"?',
              content:
                  'Si lo desactivás, los gastos de esta categoría no se suman '
                  'a los totales ni a los reportes.',
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
  group('showInfoDialog', () {
    testWidgets('renders title, content and default button label', (
      tester,
    ) async {
      await _openDialog(tester);

      expect(find.text('¿Qué significa "Cuenta como gasto"?'), findsOneWidget);
      expect(
        find.text(
          'Si lo desactivás, los gastos de esta categoría no se suman '
          'a los totales ni a los reportes.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);
    });

    testWidgets('button pops the dialog', (tester) async {
      await _openDialog(tester);

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Entendido'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Abrir'), findsOneWidget);
    });

    testWidgets('renders custom button label when provided', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => unawaited(
                showInfoDialog(
                  context: context,
                  title: 'Título',
                  content: 'Contenido',
                  buttonLabel: 'Cerrar',
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Cerrar'), findsOneWidget);
    });
  });
}
