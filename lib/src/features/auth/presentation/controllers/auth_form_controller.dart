import 'package:biyuya/src/features/auth/provider/auth_repository_provider.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_form_controller.g.dart';

@riverpod
class AuthFormController extends _$AuthFormController {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.signInWithEmailPassword(
      email: email,
      password: password,
    );

    _handleResult(result);
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String lastName,
  }) async {
    state = const AsyncLoading();

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.signUpWithEmailPassword(
      email: email,
      password: password,
      name: name,
      lastName: lastName,
    );

    _handleResult(result);
  }

  void _handleResult<T, E>(Result<T, E> result) {
    result.when(
      (success) {
        // Al tener éxito, no alteramos 'state' con data pesada. El Stream
        // nativo de Supabase en AuthSessionController reaccionará y gatillará
        // la navegación.
        state = const AsyncData(null);
      },
      (failure) {
        // Encapsulamos el AuthFailure dentro del AsyncError para que la UI
        // lo maneje con un SnackBar o Banner
        state = AsyncError(failure as Object, StackTrace.current);
      },
    );
  }
}
