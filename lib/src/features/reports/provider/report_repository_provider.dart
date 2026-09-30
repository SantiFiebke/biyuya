import 'package:biyuya/src/features/expenses/provider/expense_repository_provider.dart';
import 'package:biyuya/src/features/reports/data/repositories/report_repository_impl.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_repository_provider.g.dart';

@riverpod
ReportRepositoryBase reportRepository(Ref ref) {
  final expenseRepository = ref.watch(expenseRepositoryProvider);
  return ReportRepositoryImpl(expenseRepository);
}
