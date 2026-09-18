import 'dart:async';

import 'package:biyuya/src/core/data/widget_daily_total_sync.dart';
import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/auth/provider/auth_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_session_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthSessionController extends _$AuthSessionController {
  StreamSubscription<UserProfile?>? _profileSubscription;

  @override
  FutureOr<UserProfile?> build() {
    final authRepository = ref.watch(authRepositoryProvider);
    final completer = Completer<UserProfile?>();

    // Stream 1: auth events (login/logout/token refresh)
    final authSubscription = authRepository.onAuthStateChanged.listen(
      (userProfile) {
        state = AsyncData(userProfile);

        if (!completer.isCompleted) {
          completer.complete(userProfile);
        }

        // When auth changes, also subscribe to profile changes for this user
        if (userProfile != null) {
          _subscribeToProfileChanges(authRepository, userProfile.id);
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
    result.when((success) {
      unawaited(_profileSubscription?.cancel());
      _profileSubscription = null;
      unawaited(WidgetDailyTotalSync.clearTotal());
    }, (failure) => throw Exception(failure.message));
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

    _profileSubscription = repository.onProfileChanged(userId: userId).listen((
      userProfile,
    ) {
      if (userProfile != null) {
        state = AsyncData(userProfile);
      }
    });
  }
}
