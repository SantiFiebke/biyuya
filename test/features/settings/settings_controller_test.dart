import 'package:biyuya/src/features/settings/domain/entities/user_settings.dart';
import 'package:biyuya/src/features/settings/domain/repositories/settings_repository_base.dart';
import 'package:biyuya/src/features/settings/presentation/controllers/settings_controller.dart';
import 'package:biyuya/src/features/settings/provider/settings_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../helpers/test_helpers.dart';

/// In-memory fake: configurable success/failure, captures saved values.
/// ponytail: plain fake over mocktail — no stubbing needed for 2 methods.
class FakeSettingsRepository implements SettingsRepositoryBase {
  // Fixture stays ON so the debt-settlement setters still exercise a real
  // transition (defaults are off since the flags refactor).
  UserSettings getResult = const UserSettings(debtSettlementEnabled: true);
  bool failGet = false;
  bool failSave = false;
  int getCalls = 0;
  final List<UserSettings> savedSettings = [];

  @override
  Future<Result<UserSettings, SettingsFailure>> getSettings() async {
    getCalls++;
    if (failGet) {
      return const Error(SettingsFailure('get failed'));
    }
    return Success(getResult);
  }

  @override
  Future<Result<void, SettingsFailure>> saveSettings({
    required UserSettings settings,
  }) async {
    savedSettings.add(settings);
    if (failSave) {
      return const Error(SettingsFailure('save failed'));
    }
    return const Success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSettingsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeSettingsRepository();
    container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SettingsController build', () {
    test('loads settings from repo into AsyncData', () async {
      repo.getResult = const UserSettings(
        debtSettlementEnabled: true,
        monthProjectionEnabled: true,
      );

      container.read(settingsControllerProvider);
      await waitForLoad();

      final state = container.read(settingsControllerProvider);
      expect(repo.getCalls, 1);
      expect(state, isA<AsyncData<UserSettings>>());
      expect(state.value!.debtSettlementEnabled, isTrue);
      expect(state.value!.monthProjectionEnabled, isTrue);
    });

    test('getSettings failure keeps defaults, no error state', () async {
      repo.failGet = true;

      container.read(settingsControllerProvider);
      await waitForLoad();

      final state = container.read(settingsControllerProvider);
      expect(repo.getCalls, 1);
      expect(state, isA<AsyncData<UserSettings>>());
      expect(state.hasError, isFalse);
      expect(state.value!.debtSettlementEnabled, isFalse);
      expect(state.value!.monthProjectionEnabled, isFalse);
      expect(state.value!.debtSettlementExplainerSeen, isFalse);
      expect(state.value!.monthProjectionExplainerSeen, isFalse);
    });
  });

  group('SettingsController.setDebtSettlementEnabled', () {
    test('success saves false and state disabled', () async {
      container.read(settingsControllerProvider);
      await waitForLoad();

      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.setDebtSettlementEnabled(enabled: false);

      expect(
        container.read(settingsControllerProvider).value!.debtSettlementEnabled,
        isFalse,
      );
      expect(repo.savedSettings.single.debtSettlementEnabled, isFalse);
    });

    test('save failure reverts state to previous value', () async {
      container.read(settingsControllerProvider);
      await waitForLoad();

      repo.failSave = true;
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.setDebtSettlementEnabled(enabled: false);

      expect(
        container.read(settingsControllerProvider).value!.debtSettlementEnabled,
        isTrue,
      );
      expect(repo.savedSettings.single.debtSettlementEnabled, isFalse);
    });

    test('success saves true when re-enabling from disabled', () async {
      repo.getResult = const UserSettings();

      container.read(settingsControllerProvider);
      await waitForLoad();

      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.setDebtSettlementEnabled(enabled: true);

      expect(
        container.read(settingsControllerProvider).value!.debtSettlementEnabled,
        isTrue,
      );
      expect(repo.savedSettings.single.debtSettlementEnabled, isTrue);
    });
  });

  group('SettingsController month projection flag', () {
    test('setMonthProjectionEnabled(true) updates state and saves', () async {
      repo.getResult = const UserSettings();

      container.read(settingsControllerProvider);
      await waitForLoad();

      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.setMonthProjectionEnabled(enabled: true);

      expect(
        container
            .read(settingsControllerProvider)
            .value!
            .monthProjectionEnabled,
        isTrue,
      );
      expect(repo.savedSettings.single.monthProjectionEnabled, isTrue);
      // Other flags ride along untouched.
      expect(repo.savedSettings.single.debtSettlementEnabled, isFalse);
    });

    test('save failure rolls state back to previous value', () async {
      repo.getResult = const UserSettings();

      container.read(settingsControllerProvider);
      await waitForLoad();

      repo.failSave = true;
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.setMonthProjectionEnabled(enabled: true);

      expect(
        container
            .read(settingsControllerProvider)
            .value!
            .monthProjectionEnabled,
        isFalse,
      );
      expect(repo.savedSettings.single.monthProjectionEnabled, isTrue);
    });

    test('markMonthProjectionExplainerSeen sets the seen flag', () async {
      container.read(settingsControllerProvider);
      await waitForLoad();

      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.markMonthProjectionExplainerSeen();

      expect(
        container
            .read(settingsControllerProvider)
            .value!
            .monthProjectionExplainerSeen,
        isTrue,
      );
      expect(repo.savedSettings.single.monthProjectionExplainerSeen, isTrue);
      // Seen-flag write must not flip the feature flag itself.
      expect(
        container
            .read(settingsControllerProvider)
            .value!
            .monthProjectionEnabled,
        isFalse,
      );
    });

    test('markDebtSettlementExplainerSeen sets the seen flag', () async {
      container.read(settingsControllerProvider);
      await waitForLoad();

      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.markDebtSettlementExplainerSeen();

      expect(
        container
            .read(settingsControllerProvider)
            .value!
            .debtSettlementExplainerSeen,
        isTrue,
      );
      expect(repo.savedSettings.single.debtSettlementExplainerSeen, isTrue);
    });

    test('save failure keeps explainer seen flag off', () async {
      container.read(settingsControllerProvider);
      await waitForLoad();

      repo.failSave = true;
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.markMonthProjectionExplainerSeen();

      expect(
        container
            .read(settingsControllerProvider)
            .value!
            .monthProjectionExplainerSeen,
        isFalse,
      );
      expect(repo.savedSettings.single.monthProjectionExplainerSeen, isTrue);
    });
  });
}
