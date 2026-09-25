import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/features/expenses/domain/debt_settlement.dart';
import 'package:material_ui/material_ui.dart';

/// Shows a modal bottom sheet with this month's debt settlements.
Future<void> showDebtSettlementSheet(
  BuildContext context, {
  required List<DebtTransfer> transfers,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) =>
        SafeArea(child: DebtSettlementSheet(transfers: transfers)),
  );
}

/// Dumb view of the transfers needed to square up the household.
class DebtSettlementSheet extends StatelessWidget {
  const DebtSettlementSheet({required this.transfers, super.key});

  final List<DebtTransfer> transfers;

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Ya están a mano este mes', textAlign: TextAlign.center),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Text(
            'Liquidación de deudas',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const Divider(height: 1),
        ...transfers.map(
          (transfer) => ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    '${transfer.fromName} debe transferir',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                AmountText(amount: transfer.amount),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'a ${transfer.toName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
