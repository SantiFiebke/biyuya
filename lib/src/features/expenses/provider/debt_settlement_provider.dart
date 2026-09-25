import 'package:biyuya/src/features/auth/provider/household_members_provider.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/debt_settlement.dart';
import 'package:biyuya/src/features/expenses/domain/expense_totals.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'debt_settlement_provider.g.dart';

/// Derived value: transfers that square up the household for [year]/[month].
/// No I/O — recomputed when expenses or members change.
@riverpod
List<DebtTransfer> debtSettlement(
  Ref ref, {
  required int year,
  required int month,
}) {
  final expenses = ref.watch(expenseControllerProvider).value ?? const [];
  final members = ref.watch(householdMembersProvider).value ?? const [];
  final categories = ref.watch(categoryControllerProvider).value ?? const [];
  return settleDebts(
    expenses: expenses,
    members: members,
    year: year,
    month: month,
    excludedCategoryIds: excludedCategoryIds(categories),
  );
}
