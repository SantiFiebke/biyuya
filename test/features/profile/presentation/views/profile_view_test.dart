import 'package:biyuya/src/features/auth/domain/entities/household_data.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:biyuya/src/features/profile/presentation/views/profile_view.dart';
import 'package:biyuya/src/features/settings/domain/entities/user_settings.dart';
import 'package:biyuya/src/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncValue;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

class FakeHouseholdName extends HouseholdName {
  HouseholdData? data;

  @override
  Future<HouseholdData?> build() async => data;
}

// Overrides build() (bypasses Supabase _load) and toggle() (records calls).
class FakeSettingsController extends SettingsController {
  FakeSettingsController({this.initial = const UserSettings()});

  final UserSettings initial;
  final List<bool> toggledWith = [];

  @override
  AsyncValue<UserSettings> build() => AsyncData(initial);

  @override
  Future<void> toggle({required bool enabled}) async {
    toggledWith.add(enabled);
    state = AsyncData(state.value!.copyWith(debtSettlementEnabled: enabled));
  }
}

List<Override> _baseOverrides({
  HouseholdData? householdData = const HouseholdData(name: 'Mi Hogar'),
  UserSettings settings = const UserSettings(),
  FakeSettingsController? settingsController,
}) {
  final fakeNotifier = FakeHouseholdName()..data = householdData;
  return [
    authSessionControllerProvider.overrideWith(FakeAuthSessionController.new),
    householdNameProvider.overrideWith(() => fakeNotifier),
    settingsControllerProvider.overrideWith(
      () => settingsController ?? FakeSettingsController(initial: settings),
    ),
  ];
}

Finder _debtSettlementSwitch() => find.descendant(
  of: find.widgetWithText(SwitchListTile, 'Liquidación de deudas'),
  matching: find.byType(Switch),
);

void main() {
  group('ProfileView', () {
    testWidgets('renders user name', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ProfileView(), overrides: _baseOverrides()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('shows household info', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ProfileView(), overrides: _baseOverrides()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mi Hogar'), findsOneWidget);
    });

    testWidgets('logout button exists', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ProfileView(), overrides: _baseOverrides()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('debt settlement switch visible and enabled by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(child: const ProfileView(), overrides: _baseOverrides()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.widgetWithText(SwitchListTile, 'Liquidación de deudas'),
        findsOneWidget,
      );
      expect(tester.widget<Switch>(_debtSettlementSwitch()).value, isTrue);
    });

    testWidgets('debt settlement switch reflects disabled setting', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ProfileView(),
          overrides: _baseOverrides(
            settings: const UserSettings(debtSettlementEnabled: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.widgetWithText(SwitchListTile, 'Liquidación de deudas'),
        findsOneWidget,
      );
      expect(tester.widget<Switch>(_debtSettlementSwitch()).value, isFalse);
    });

    testWidgets('tapping debt settlement switch calls toggle(enabled: false)', (
      tester,
    ) async {
      final fakeSettings = FakeSettingsController();
      await tester.pumpWidget(
        wrapTest(
          child: const ProfileView(),
          overrides: _baseOverrides(settingsController: fakeSettings),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.widget<Switch>(_debtSettlementSwitch()).value, isTrue);

      await tester.tap(_debtSettlementSwitch());
      await tester.pump();

      expect(fakeSettings.toggledWith, [false]);
      expect(tester.widget<Switch>(_debtSettlementSwitch()).value, isFalse);
    });
  });
}
