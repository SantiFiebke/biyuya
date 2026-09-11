import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/features/auth/domain/entities/household.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/auth/provider/auth_repository_provider.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

@riverpod
class OnboardingController extends _$OnboardingController {
  Household? _createdHousehold;

  Household? get createdHousehold => _createdHousehold;

  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> createNewHousehold(String name) async {
    state = const AsyncLoading();

    final supabaseClient = ref.read(supabaseClientProvider);
    final userId = supabaseClient.auth.currentUser?.id;

    if (userId == null) {
      state = AsyncError(
        const AuthFailure('No se encontró una sesión activa de usuario.'),
        StackTrace.current,
      );
      return;
    }

    final repository = ref.read(authRepositoryProvider);

    final result = await repository.createHousehold(
      householdName: name,
      userId: userId,
    );

    result.when(
      (household) {
        _createdHousehold = household;
        state = const AsyncData(null);
      },
      (failure) {
        state = AsyncError(failure as Object, StackTrace.current);
      },
    );
  }

  Future<void> joinExistingHousehold(String inviteCode) async {
    state = const AsyncLoading();

    final supabaseClient = ref.read(supabaseClientProvider);
    final userId = supabaseClient.auth.currentUser?.id;

    if (userId == null) {
      state = AsyncError(
        const AuthFailure('No se encontró una sesión activa de usuario.'),
        StackTrace.current,
      );
      return;
    }

    final repository = ref.read(authRepositoryProvider);

    final result = await repository.joinHousehold(
      inviteCode: inviteCode,
      userId: userId,
    );

    _handleResult(result);
  }

  void _handleResult<T, E>(Result<T, E> result) {
    result.when(
      (success) {
        state = const AsyncData(null);
      },
      (failure) {
        state = AsyncError(failure as Object, StackTrace.current);
      },
    );
  }
}
