import 'package:biyuya/src/features/auth/domain/entities/household.dart';
import 'package:biyuya/src/features/auth/provider/auth_repository_provider.dart';
import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  AsyncValue<Household?> build() {
    return const AsyncData(null);
  }

  Future<void> createNewHousehold(String name) async {
    state = const AsyncLoading();

    final repository = ref.read(authRepositoryProvider);

    final result = await repository.createHousehold(householdName: name);

    result.when(
      (household) {
        ref
          ..invalidate(categoryControllerProvider)
          ..invalidate(householdNameProvider);
        state = AsyncData(household);
      },
      (failure) {
        state = AsyncError(failure as Object, StackTrace.current);
      },
    );
  }

  Future<void> joinExistingHousehold(String inviteCode) async {
    state = const AsyncLoading();

    final repository = ref.read(authRepositoryProvider);

    final result = await repository.joinHousehold(inviteCode: inviteCode);

    result.when(
      (success) {
        ref
          ..invalidate(categoryControllerProvider)
          ..invalidate(householdNameProvider);
        state = const AsyncData(null);
      },
      (failure) {
        state = AsyncError(failure as Object, StackTrace.current);
      },
    );
  }
}
