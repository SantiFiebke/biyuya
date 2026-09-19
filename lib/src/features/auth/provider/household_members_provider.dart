import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/auth_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'household_members_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<UserProfile>> householdMembers(Ref ref) async {
  final session = ref.watch(authSessionControllerProvider);
  final householdId = session.value?.householdId;

  if (householdId == null || householdId.isEmpty) {
    return [];
  }

  final repository = ref.watch(authRepositoryProvider);
  final result = await repository.getHouseholdMembers(
    householdId: int.parse(householdId),
  );

  final members = result.when(
    (members) => members,
    (failure) => throw Exception(failure.message),
  );
  return members;
}
