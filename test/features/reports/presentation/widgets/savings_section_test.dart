import 'package:biyuya/src/core/presentation/widgets/amount_text.dart';
import 'package:biyuya/src/features/reports/domain/entities/savings_report.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/savings_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_helpers.dart';

SavingsEntry makeEntry({
  DateTime? date,
  double amount = 500,
  String? description,
  String? source,
}) {
  return SavingsEntry(
    date: date ?? DateTime(2025, 7, 10),
    amount: amount,
    description: description,
    source: source,
  );
}

SavingsReport makeReport({
  double totalSaved = 3000,
  double goalAmount = 10000,
  double progressPct = 30,
  List<SavingsEntry> entries = const [],
}) {
  return SavingsReport(
    year: 2025,
    month: 7,
    totalSaved: totalSaved,
    goalAmount: goalAmount,
    progressPct: progressPct,
    entries: entries,
  );
}

void main() {
  group('SavingsSection', () {
    testWidgets('renders total saved and progress toward goal', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: SavingsSection(report: makeReport())),
      );

      expect(find.text('Ahorro del mes'), findsOneWidget);
      expect(find.text('Total ahorrado'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);

      final amount = tester.widget<AmountText>(
        find.byWidgetPredicate(
          (widget) => widget is AmountText && widget.amount == 3000,
        ),
      );
      expect(amount.amount, 3000);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders entries list with date, description and amount', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: SavingsSection(
            report: makeReport(
              entries: [
                makeEntry(
                  date: DateTime(2025, 7, 10),
                  amount: 1500,
                  description: 'Ahorro julio',
                ),
                makeEntry(date: DateTime(2025, 7, 2), source: 'Transferencia'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('10/07'), findsOneWidget);
      expect(find.text('02/07'), findsOneWidget);
      expect(find.text('Ahorro julio'), findsOneWidget);
      expect(find.text('Transferencia'), findsOneWidget);
      expect(find.text('Sin ahorros este mes'), findsNothing);

      final amounts = tester
          .widgetList<AmountText>(find.byType(AmountText))
          .map((widget) => widget.amount);
      expect(amounts, containsAll(<double>[3000, 1500, 500]));
    });

    testWidgets('falls back to Sin descripción when text missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: SavingsSection(report: makeReport(entries: [makeEntry()])),
        ),
      );

      expect(find.text('Sin descripción'), findsOneWidget);
    });

    testWidgets('renders empty state when there are no entries', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(child: SavingsSection(report: makeReport())),
      );

      expect(find.text('Sin ahorros este mes'), findsOneWidget);
      expect(find.byType(Divider), findsNothing);
    });
  });
}
