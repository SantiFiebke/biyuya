import 'package:biyuya/src/core/network/network_timeout.dart';
import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/features/auth/domain/entities/household_data.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'household_provider.g.dart';

@Riverpod(keepAlive: true)
class HouseholdName extends _$HouseholdName {
  @override
  Future<HouseholdData?> build() async {
    final householdId = ref
        .watch(authSessionControllerProvider)
        .value
        ?.householdIdValue;

    if (householdId == null) {
      return null;
    }

    try {
      final client = ref.read(supabaseClientProvider);
      final data = await client
          .from('households')
          .select('name, invite_code')
          .eq('id', householdId)
          .single()
          .timeout(kNetworkTimeout);

      return HouseholdData(
        name: data['name'] as String,
        inviteCode: data['invite_code'] as String?,
      );
    } on Object catch (_) {
      return null;
    }
  }

  Future<void> updateName(String newName) async {
    final householdId = ref
        .read(authSessionControllerProvider)
        .value
        ?.householdIdValue;

    if (householdId == null) {
      return;
    }

    final client = ref.read(supabaseClientProvider);
    await client
        .from('households')
        .update({'name': newName})
        .eq('id', householdId)
        .timeout(kNetworkTimeout);

    ref.invalidateSelf();
  }
}
