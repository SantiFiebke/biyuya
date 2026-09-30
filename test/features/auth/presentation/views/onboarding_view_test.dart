import 'package:biyuya/src/features/auth/domain/entities/household.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/onboarding_controller.dart';
import 'package:biyuya/src/features/auth/presentation/views/onboarding_view.dart';
import 'package:biyuya/src/features/auth/presentation/widgets/create_household_form.dart';
import 'package:biyuya/src/features/auth/presentation/widgets/join_household_form.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

class _NoopOnboardingController extends OnboardingController {
  @override
  AsyncValue<Household?> build() => const AsyncData(null);

  @override
  Future<void> createNewHousehold(String name) async {}

  @override
  Future<void> joinExistingHousehold(String inviteCode) async {}
}

List<Override> _overrides() => [
  onboardingControllerProvider.overrideWith(_NoopOnboardingController.new),
  authSessionControllerProvider.overrideWith(FakeAuthSessionController.new),
];

void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (methodCall) async => null,
        );
  });

  group('OnboardingView', () {
    testWidgets('default shows CreateHouseholdForm', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const OnboardingView(), overrides: _overrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configurar Hogar'), findsOneWidget);
      expect(find.byType(CreateHouseholdForm), findsOneWidget);
      expect(find.byType(JoinHouseholdForm), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('selecting Unirme shows JoinHouseholdForm', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const OnboardingView(), overrides: _overrides()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unirme'));
      await tester.pumpAndSettle();

      expect(find.byType(JoinHouseholdForm), findsOneWidget);
      expect(find.byType(CreateHouseholdForm), findsNothing);
      expect(find.text('Código de invitación'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('back arrow opens logout confirm dialog', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const OnboardingView(), overrides: _overrides()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Cerrar sesión'), findsWidgets);
      expect(find.text('¿Seguro que deseas cerrar sesión?'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancelar'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
