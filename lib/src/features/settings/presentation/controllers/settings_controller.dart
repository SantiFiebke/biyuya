import 'dart:async';

import 'package:biyuya/src/features/settings/domain/entities/user_settings.dart';
import 'package:biyuya/src/features/settings/provider/settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_controller.g.dart';

@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  bool _touched = false;

  @override
  AsyncValue<UserSettings> build() {
    // ponytail: reset dirty flag — notifier instance survives invalidate, so
    // the flag is scoped per load cycle, not per app run.
    _touched = false;
    unawaited(Future.microtask(_load));
    return const AsyncData(UserSettings());
  }

  Future<void> _load() async {
    if (_touched) {
      return;
    }
    final result = await ref.read(settingsRepositoryProvider).getSettings();
    if (_touched) {
      return;
    }
    result.when(
      (settings) => state = AsyncData(settings),
      // ponytail: online-first v1 — failure keeps defaults so UI never blocks
      // on settings; SharedPreferences cache only if staleness ever bothers.
      (_) => state = const AsyncData(UserSettings()),
    );
  }

  Future<void> toggle({required bool enabled}) async {
    _touched = true;
    final previous = state.value ?? const UserSettings();
    state = AsyncData(previous.copyWith(debtSettlementEnabled: enabled));

    final result = await ref
        .read(settingsRepositoryProvider)
        .saveSettings(debtSettlementEnabled: enabled);

    result.when((_) {}, (_) => state = AsyncData(previous));
  }
}
