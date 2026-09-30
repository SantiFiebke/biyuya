import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/features/categories/provider/category_repository_provider.dart';
import 'package:biyuya/src/features/reports/data/repositories/report_repository_impl.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_repository_provider.g.dart';

@riverpod
ReportRepositoryBase reportRepository(Ref ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  return ReportRepositoryImpl(supabaseClient, categoryRepository);
}
