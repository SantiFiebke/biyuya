import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expense_repository_provider.g.dart';

@riverpod
ExpenseRepositoryBase expenseRepository(Ref ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ExpenseRepositoryImpl(supabaseClient);
}
