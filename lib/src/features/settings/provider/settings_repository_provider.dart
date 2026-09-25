import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:biyuya/src/features/settings/domain/repositories/settings_repository_base.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_repository_provider.g.dart';

@riverpod
SettingsRepositoryBase settingsRepository(Ref ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SettingsRepositoryImpl(supabaseClient);
}
