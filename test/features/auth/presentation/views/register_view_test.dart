import 'package:biyuya/src/features/auth/presentation/controllers/auth_form_controller.dart';
import 'package:biyuya/src/features/auth/presentation/views/register_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

class _NoopAuthFormController extends AuthFormController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String lastName,
    required bool acceptedTerms,
  }) async {}

  @override
  Future<void> login({required String email, required String password}) async {}
}

List<Override> _overrides() => [
  authFormControllerProvider.overrideWith(_NoopAuthFormController.new),
];

void main() {
  group('RegisterView validation', () {
    testWidgets('shows error for weak password', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const RegisterView(), overrides: _overrides()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre'),
        'Ana',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Apellido'),
        'Perez',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'a@b.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'abcdef',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar Contraseña'),
        'abcdef',
      );

      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Registrarme'));
      await tester.tap(find.text('Registrarme'));
      await tester.pumpAndSettle();

      expect(find.text('Debe incluir al menos una mayúscula'), findsOneWidget);
    });

    testWidgets('shows error for invalid email', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const RegisterView(), overrides: _overrides()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'foo',
      );

      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Registrarme'));
      await tester.tap(find.text('Registrarme'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresá un correo válido'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const RegisterView(), overrides: _overrides()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'Abcdef1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar Contraseña'),
        'Xyz1234',
      );

      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Registrarme'));
      await tester.tap(find.text('Registrarme'));
      await tester.pumpAndSettle();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });
  });
}
