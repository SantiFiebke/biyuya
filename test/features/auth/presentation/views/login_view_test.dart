import 'package:biyuya/src/features/auth/presentation/controllers/auth_form_controller.dart';
import 'package:biyuya/src/features/auth/presentation/views/login_view.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

class _NoopAuthFormController extends AuthFormController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String lastName,
  }) async {}
}

List<Override> _overrides() => [
  authFormControllerProvider.overrideWith(_NoopAuthFormController.new),
];

void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (methodCall) async => null,
        );
  });

  group('LoginView', () {
    testWidgets('renders title, subtitle and both fields', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const LoginView(), overrides: _overrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cuentas claras'), findsOneWidget);
      expect(find.text('Control de gastos transparente'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('shows Iniciar Sesión button', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const LoginView(), overrides: _overrides()),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(ElevatedButton, 'Iniciar Sesión'),
        findsOneWidget,
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('password visibility toggle switches obscureText', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(child: const LoginView(), overrides: _overrides()),
      );
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextField).at(1);
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('empty submit shows validation errors', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const LoginView(), overrides: _overrides()),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Iniciar Sesión'));
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresá tu correo'), findsOneWidget);
      expect(find.text('Ingresá tu contraseña'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('shows register link', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const LoginView(), overrides: _overrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('¿No tenés cuenta? Registrate acá'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
