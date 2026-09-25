import 'dart:math';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:equatable/equatable.dart';

/// One money transfer needed to square up the household for a month.
class DebtTransfer extends Equatable {
  const DebtTransfer({
    required this.fromUuid,
    required this.fromName,
    required this.toUuid,
    required this.toName,
    required this.amount,
  });

  final String fromUuid;
  final String fromName;
  final String toUuid;
  final String toName;
  final double amount;

  @override
  List<Object?> get props => [fromUuid, fromName, toUuid, toName, amount];
}

const _epsilon = 0.005;

double _round2(double value) => (value * 100).round() / 100;

/// Min-cash-flow settlement: every member owes an equal share of the month's
/// expenses; returns the transfers that square everyone up (greedy match of
/// largest debtor against largest creditor until no balance exceeds [_epsilon]).
List<DebtTransfer> settleDebts({
  required List<Expense> expenses,
  required List<UserProfile> members,
  required int year,
  required int month,
}) {
  if (members.isEmpty) {
    return const [];
  }

  final monthExpenses = expenses.where(
    (e) => e.date.year == year && e.date.month == month,
  );
  // ponytail: gastos sin pagador asignado quedan fuera del cálculo de saldos
  final included = monthExpenses.where((e) => e.userUuid != null).toList();

  final names = {for (final m in members) m.id: '${m.name} ${m.lastName}'};
  final paid = <String, double>{};
  for (final expense in included) {
    final uuid = expense.userUuid!;
    paid.update(
      uuid,
      (value) => value + expense.amount,
      ifAbsent: () => expense.amount,
    );
    names[uuid] = expense.userName ?? names[uuid] ?? uuid;
  }

  final total = included.fold<double>(0, (sum, e) => sum + e.amount);
  final share = total / members.length;
  final balances = <String, double>{
    for (final m in members) m.id: (paid[m.id] ?? 0.0) - share,
  };

  // Exact cents total the transfers must add up to.
  final target = _round2(
    balances.values
        .where((v) => v > _epsilon)
        .fold<double>(0, (sum, v) => sum + v),
  );

  final working = Map<String, double>.of(balances);
  final transfers = <DebtTransfer>[];
  while (true) {
    final creditors = working.entries.where((e) => e.value > _epsilon).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final debtors = working.entries.where((e) => e.value < -_epsilon).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (creditors.isEmpty || debtors.isEmpty) {
      break;
    }

    final debtor = debtors.first;
    final creditor = creditors.first;
    final matched = min(-debtor.value, creditor.value);
    working[debtor.key] = debtor.value + matched;
    working[creditor.key] = creditor.value - matched;
    transfers.add(
      DebtTransfer(
        fromUuid: debtor.key,
        fromName: names[debtor.key] ?? debtor.key,
        toUuid: creditor.key,
        toName: names[creditor.key] ?? creditor.key,
        amount: matched,
      ),
    );
  }

  if (transfers.isEmpty) {
    return const [];
  }

  // Round every transfer to cents; the last one absorbs the residual so the
  // emitted amounts sum exactly to [target].
  var allocated = 0.0;
  for (var i = 0; i < transfers.length - 1; i++) {
    final rounded = _round2(transfers[i].amount);
    allocated += rounded;
    final t = transfers[i];
    transfers[i] = DebtTransfer(
      fromUuid: t.fromUuid,
      fromName: t.fromName,
      toUuid: t.toUuid,
      toName: t.toName,
      amount: rounded,
    );
  }

  final last = transfers.last;
  final residual = _round2(target - allocated);
  transfers[transfers.length - 1] = DebtTransfer(
    fromUuid: last.fromUuid,
    fromName: last.fromName,
    toUuid: last.toUuid,
    toName: last.toName,
    // Guard positive: rounding earlier transfers can push the residual to 0.
    amount: residual > 0 ? residual : _round2(last.amount),
  );

  return transfers;
}
