import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/auth/provider/auth_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_session_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthSessionController extends _$AuthSessionController {
  StreamSubscription<UserProfile?>? _profileSubscription;

  @override
  FutureOr<UserProfile?> build() async {
    final authRepository = ref.watch(authRepositoryProvider);

    // Stream 1: auth events (login/logout/token refresh)
    final authSubscription = authRepository.onAuthStateChanged.listen(
      (userProfile) {
        state = AsyncData(userProfile);

        // When auth changes, also subscribe to profile changes for this user
        if (userProfile != null) {
          _subscribeToProfileChanges(authRepository, userProfile.id);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );

    ref.onDispose(authSubscription.cancel);
    ref.onDispose(() => _profileSubscription?.cancel());

    return null;
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
