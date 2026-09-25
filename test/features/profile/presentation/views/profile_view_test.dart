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

// Overrides build() (bypasses Supabase _load) and the setters (record calls).
class FakeSettingsController extends SettingsController {
  FakeSettingsController({this.initial = const UserSettings()});

  final UserSettings initial;
  final List<bool> debtSettlementWith = [];
  final List<bool> monthProjectionWith = [];
  int debtExplainerSeenCalls = 0;
  int monthExplainerSeenCalls = 0;

  @override
  AsyncValue<UserSettings> build() => AsyncData(initial);

  @override
  Future<void> setDebtSettlementEnabled({required bool enabled}) async {
    debtSettlementWith.add(enabled);
    state = AsyncData(state.value!.copyWith(debtSettlementEnabled: enabled));
  }

  @override
  Future<void> setMonthProjectionEnabled({required bool enabled}) async {
    monthProjectionWith.add(enabled);
    state = AsyncData(state.value!.copyWith(monthProjectionEnabled: enabled));
  }

  @override
  Future<void> markDebtSettlementExplainerSeen() async {
    debtExplainerSeenCalls++;
    state = AsyncData(state.value!.copyWith(debtSettlementExplainerSeen: true));
  }

  @override
  Future<void> markMonthProjectionExplainerSeen() async {
    monthExplainerSeenCalls++;
    state = AsyncData(
      state.value!.copyWith(monthProjectionExplainerSeen: true),
    );
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

Finder _monthProjectionSwitch() => find.descendant(
  of: find.widgetWithText(SwitchListTile, 'Proyección fin de mes'),
  matching: find.byType(Switch),
);

Future<void> _pumpProfile(
  WidgetTester tester, {
  List<Override>? overrides,
}) async {
  await tester.pumpWidget(
    wrapTest(
      child: const ProfileView(),
      overrides: overrides ?? _baseOverrides(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('ProfileView', () {
    testWidgets('renders user name', (tester) async {
      await _pumpProfile(tester);

      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('shows household info', (tester) async {
      await _pumpProfile(tester);

      expect(find.text('Mi Hogar'), findsOneWidget);
    });

    testWidgets('logout button exists', (tester) async {
      await _pumpProfile(tester);

      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('debt settlement switch visible and off by default', (
      tester,
    ) async {
      await _pumpProfile(tester);

      expect(
        find.widgetWithText(SwitchListTile, 'Liquidación de deudas'),
        findsOneWidget,
      );
      expect(tester.widget<Switch>(_debtSettlementSwitch()).value, isFalse);
    });

    testWidgets('debt settlement switch reflects enabled setting', (
      tester,
    ) async {
      await _pumpProfile(
        tester,
        overrides: _baseOverrides(
          settings: const UserSettings(debtSettlementEnabled: true),
        ),
      );

      expect(
        find.widgetWithText(SwitchListTile, 'Liquidación de deudas'),
        findsOneWidget,
      );
      expect(tester.widget<Switch>(_debtSettlementSwitch()).value, isTrue);
    });

    testWidgets(
      'tapping debt settlement switch calls setDebtSettlementEnabled(false)',
      (tester) async {
        final fakeSettings = FakeSettingsController(
          initial: const UserSettings(debtSettlementEnabled: true),
        );
        await _pumpProfile(
          tester,
          overrides: _baseOverrides(settingsController: fakeSettings),
        );

        expect(tester.widget<Switch>(_debtSettlementSwitch()).value, isTrue);

        await tester.ensureVisible(_debtSettlementSwitch());
        await tester.tap(_debtSettlementSwitch());
        await tester.pumpAndSettle();

        // Turning OFF skips the explainer dialog entirely.
        expect(find.byType(AlertDialog), findsNothing);
        expect(fakeSettings.debtSettlementWith, [false]);
        expect(fakeSettings.debtExplainerSeenCalls, 0);
        expect(tester.widget<Switch>(_debtSettlementSwitch()).value, isFalse);
      },
    );
  });

  group('ProfileView month projection explainer', () {
    testWidgets('first ON shows the confirm dialog and enables nothing yet', (
      tester,
    ) async {
      final fakeSettings = FakeSettingsController();
      await _pumpProfile(
        tester,
        overrides: _baseOverrides(settingsController: fakeSettings),
      );

      await tester.ensureVisible(_monthProjectionSwitch());
      await tester.tap(_monthProjectionSwitch());
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('Proyección fin de mes'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('Activar')),
        findsOneWidget,
      );

      expect(fakeSettings.monthProjectionWith, isEmpty);
      expect(fakeSettings.monthExplainerSeenCalls, 0);
      expect(tester.widget<Switch>(_monthProjectionSwitch()).value, isFalse);
    });

    testWidgets('confirming enables the flag and marks the explainer seen', (
      tester,
    ) async {
      final fakeSettings = FakeSettingsController();
      await _pumpProfile(
        tester,
        overrides: _baseOverrides(settingsController: fakeSettings),
      );

      await tester.ensureVisible(_monthProjectionSwitch());
      await tester.tap(_monthProjectionSwitch());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Activar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(fakeSettings.monthProjectionWith, [true]);
      expect(fakeSettings.monthExplainerSeenCalls, 1);
      expect(tester.widget<Switch>(_monthProjectionSwitch()).value, isTrue);
    });

    testWidgets('cancelling leaves the flag off and unseen', (tester) async {
      final fakeSettings = FakeSettingsController();
      await _pumpProfile(
        tester,
        overrides: _baseOverrides(settingsController: fakeSettings),
      );

      await tester.ensureVisible(_monthProjectionSwitch());
      await tester.tap(_monthProjectionSwitch());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(fakeSettings.monthProjectionWith, isEmpty);
      expect(fakeSettings.monthExplainerSeenCalls, 0);
      expect(tester.widget<Switch>(_monthProjectionSwitch()).value, isFalse);
    });

    testWidgets('no dialog when the explainer was already seen', (
      tester,
    ) async {
      final fakeSettings = FakeSettingsController(
        initial: const UserSettings(monthProjectionExplainerSeen: true),
      );
      await _pumpProfile(
        tester,
        overrides: _baseOverrides(settingsController: fakeSettings),
      );

      await tester.ensureVisible(_monthProjectionSwitch());
      await tester.tap(_monthProjectionSwitch());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(fakeSettings.monthProjectionWith, [true]);
      expect(fakeSettings.monthExplainerSeenCalls, 0);
      expect(tester.widget<Switch>(_monthProjectionSwitch()).value, isTrue);
    });
  });
}
