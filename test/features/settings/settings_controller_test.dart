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
  UserSettings getResult = const UserSettings();
  bool failGet = false;
  bool failSave = false;
  int getCalls = 0;
  final List<bool> savedValues = [];

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
    required bool debtSettlementEnabled,
  }) async {
    savedValues.add(debtSettlementEnabled);
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
      repo.getResult = const UserSettings(debtSettlementEnabled: false);

      container.read(settingsControllerProvider);
      await waitForLoad();

      final state = container.read(settingsControllerProvider);
      expect(repo.getCalls, 1);
      expect(state, isA<AsyncData<UserSettings>>());
      expect(state.value!.debtSettlementEnabled, isFalse);
    });

    test('getSettings failure keeps defaults, no error state', () async {
      repo.failGet = true;

      container.read(settingsControllerProvider);
      await waitForLoad();

      final state = container.read(settingsControllerProvider);
      expect(repo.getCalls, 1);
      expect(state, isA<AsyncData<UserSettings>>());
      expect(state.hasError, isFalse);
      expect(state.value!.debtSettlementEnabled, isTrue);
    });
  });

  group('SettingsController.toggle', () {
    test('success saves false and state disabled', () async {
      container.read(settingsControllerProvider);
      await waitForLoad();

      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.toggle(enabled: false);

      expect(
        container.read(settingsControllerProvider).value!.debtSettlementEnabled,
        isFalse,
      );
      expect(repo.savedValues, [false]);
    });

    test('save failure reverts state to previous value', () async {
      container.read(settingsControllerProvider);
      await waitForLoad();

      repo.failSave = true;
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.toggle(enabled: false);

      expect(
        container.read(settingsControllerProvider).value!.debtSettlementEnabled,
        isTrue,
      );
      expect(repo.savedValues, [false]);
    });

    test('success saves true when re-enabling from disabled', () async {
      repo.getResult = const UserSettings(debtSettlementEnabled: false);

      container.read(settingsControllerProvider);
      await waitForLoad();

      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.toggle(enabled: true);

      expect(
        container.read(settingsControllerProvider).value!.debtSettlementEnabled,
        isTrue,
      );
      expect(repo.savedValues, [true]);
    });
  });
}
