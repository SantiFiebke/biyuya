import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/features/categories/data/repositories/category_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_repository_provider.g.dart';

@riverpod
CategoryRepositoryImpl categoryRepository(Ref ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return CategoryRepositoryImpl(supabaseClient);
}
