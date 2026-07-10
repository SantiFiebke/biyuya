import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/provider/auth_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_session_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthSessionController extends _$AuthSessionController {
  @override
  FutureOr<UserProfile?> build() async {
    final authRepository = ref.watch(authRepositoryProvider);

    final subscription = authRepository.onAuthStateChanged.listen(
      (userProfile) {
        state = AsyncData(userProfile);
      },
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );

    ref.onDispose(subscription.cancel);

    return null;
  }
}
