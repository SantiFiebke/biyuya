import 'dart:async';

import 'package:biyuya/src/core/data/widget_daily_total_sync.dart';
import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/core/provider/theme_provider.dart';
import 'package:biyuya/src/features/auth/data/local/profile_cache.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/auth/provider/auth_repository_provider.dart';
import 'package:biyuya/src/features/auth/provider/household_members_provider.dart';
import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:biyuya/src/features/categories/data/local/category_cache.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_list_controller.dart';
import 'package:biyuya/src/features/expenses/provider/expense_sync_providers.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/report_controller.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/savings_report_controller.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/weekly_report_controller.dart';
import 'package:biyuya/src/features/settings/presentation/controllers/settings_controller.dart';
import 'package:biyuya/src/navigation/provider/router_provider.dart';
import 'package:logger/logger.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_session_controller.g.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

@Riverpod(keepAlive: true)
class AuthSessionController extends _$AuthSessionController {
  StreamSubscription<UserProfile?>? _profileSubscription;
  String? _lastUserId;
  bool _resetScheduled = false;

  @override
  FutureOr<UserProfile?> build() {
    final authRepository = ref.watch(authRepositoryProvider);
    final completer = Completer<UserProfile?>();

    // Stream 1: auth events (login/logout/token refresh)
    final authSubscription = authRepository.onAuthStateChanged.listen(
      (userProfile) {
        final previousUserId = _lastUserId;
        _lastUserId = userProfile?.id;
        state = AsyncData(userProfile);

        if (!completer.isCompleted) {
          completer.complete(userProfile);
        }

        // When auth changes, also subscribe to profile changes for this user
        if (userProfile != null) {
          _subscribeToProfileChanges(authRepository, userProfile.id);
        } else {
          unawaited(_profileSubscription?.cancel());
          _profileSubscription = null;
        }

        // Session dropped (token expiry / remote sign-out) or user switched:
        // reset stale household data so the next account never sees it.
        // Any null emission counts — on cold start after expiry the first
        // emission is null with _lastUserId == null, and previous account's
        // pending expenses/widget/theme must still be cleared. Reset is
        // idempotent, so a no-session cold start is harmless.
        // Microtask: ref.container.invalidate during build would assert.
        final userChanged =
            userProfile != null &&
            previousUserId != null &&
            previousUserId != userProfile.id;
        if (userProfile == null || userChanged) {
          _scheduleResetSessionState();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError(error, stackTrace);
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );

    ref.onDispose(authSubscription.cancel);
    ref.onDispose(() => _profileSubscription?.cancel());

    return completer.future;
  }

  Future<void> signOut() async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.signOut();
    await result.when((success) async {
      unawaited(_profileSubscription?.cancel());
      _profileSubscription = null;
      await _resetSessionState();
    }, (failure) async => throw Exception(failure.message));
  }

  Future<Result<void, AuthFailure>> leaveHousehold() async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.leaveHousehold();
    result.when((_) {
      _invalidateHouseholdData();
      unawaited(_clearLocalHouseholdData());
      unawaited(WidgetDailyTotalSync.clearTotal());
    }, (_) {});
    return result;
  }

  Future<Result<void, AuthFailure>> deleteHousehold() async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.deleteHousehold();
    result.when((_) {
      _invalidateHouseholdData();
      unawaited(_clearLocalHouseholdData());
      unawaited(WidgetDailyTotalSync.clearTotal());
    }, (_) {});
    return result;
  }

  Future<Result<void, AuthFailure>> deleteAccount() async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.deleteAccount();
    await result.when((_) async {
      unawaited(_profileSubscription?.cancel());
      _profileSubscription = null;
      await _resetSessionState();
    }, (_) async {});
    return result;
  }

  Future<void> _resetSessionState() async {
    _invalidateHouseholdData();
    ref.container.invalidate(pendingDeepLinkProvider);
    await ref.read(themeProvider.notifier).reset();
    unawaited(WidgetDailyTotalSync.clearTotal());
    await _clearLocalHouseholdData();
  }

  /// Re-entry guarded: repeated null emissions (or null + explicit signOut)
  /// must not stack concurrent resets.
  void _scheduleResetSessionState() {
    if (_resetScheduled) {
      return;
    }
    _resetScheduled = true;
    unawaited(
      Future.microtask(() async {
        try {
          await _resetSessionState();
        } on Object catch (error, stackTrace) {
          _log.e('Session reset failed', error: error, stackTrace: stackTrace);
        } finally {
          _resetScheduled = false;
        }
      }),
    );
  }

  /// Drops offline pending expenses + cached categories/profile so
  /// old-household data never merges into the next household/account.
  Future<void> _clearLocalHouseholdData() async {
    await ref.read(pendingExpenseStoreProvider).clear();
    await const CategoryCache().clear();
    await const ProfileCache().clear();
  }

  void _invalidateHouseholdData() {
    ref.container
      ..invalidate(categoryControllerProvider)
      ..invalidate(expenseControllerProvider)
      ..invalidate(expenseListControllerProvider)
      ..invalidate(reportControllerProvider)
      ..invalidate(weeklyReportControllerProvider)
      ..invalidate(savingsReportControllerProvider)
      ..invalidate(householdNameProvider)
      ..invalidate(householdMembersProvider)
      ..invalidate(settingsControllerProvider);
  }

  void _subscribeToProfileChanges(
    AuthRepositoryBase repository,
    String userId,
  ) {
    // Cancel previous subscription if exists
    final previous = _profileSubscription;
    if (previous != null) {
      unawaited(previous.cancel());
    }

    _profileSubscription = repository
        .onProfileChanged(userId: userId)
        .listen(
          (userProfile) {
            if (userProfile != null) {
              state = AsyncData(userProfile);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            // Transient realtime hiccup (e.g. socket drop): keep last known state
            // instead of tearing down the auth session.
            _log.w(
              'Profile realtime subscription error',
              error: error,
              stackTrace: stackTrace,
            );
          },
          cancelOnError: false,
        );
  }
}
