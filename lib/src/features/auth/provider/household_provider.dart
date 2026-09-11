import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'household_provider.g.dart';

@Riverpod(keepAlive: true)
class HouseholdName extends _$HouseholdName {
  @override
  Future<String?> build() async {
    final session = ref.watch(authSessionControllerProvider);
    final householdId = session.value?.householdId;

    if (householdId == null || householdId.isEmpty) {
      return null;
    }

    try {
      final client = ref.read(supabaseClientProvider);
      final data = await client
          .from('households')
          .select('name')
          .eq('id', int.parse(householdId))
          .single();

      return data['name'] as String?;
    } on Object catch (_) {
      return null;
    }
  }
}
