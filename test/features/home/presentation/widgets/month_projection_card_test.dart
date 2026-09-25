import 'package:biyuya/src/features/home/presentation/widgets/month_projection_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

Future<void> _pumpCard(
  WidgetTester tester, {
  required double spentSoFar,
  required DateTime referenceDate,
}) async {
  await tester.pumpWidget(
    wrapTest(
      child: MonthProjectionCard(
        spentSoFar: spentSoFar,
        referenceDate: referenceDate,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('MonthProjectionCard', () {
    testWidgets('renders label, projected amount and days left', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        spentSoFar: 15000,
        referenceDate: DateTime(2026, 9, 24),
      );

      expect(find.text('Proyección fin de mes'), findsOneWidget);
      // 15000 / 24 * 30 = 18750 → es_AR currency: "18.750,00".
      expect(
        find.textContaining('18.750,00', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('6 días restantes'), findsOneWidget);
    });

    testWidgets('renders without error when spentSoFar is 0', (tester) async {
      await _pumpCard(
        tester,
        spentSoFar: 0,
        referenceDate: DateTime(2026, 9, 24),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Proyección fin de mes'), findsOneWidget);
      expect(find.textContaining('0,00', findRichText: true), findsOneWidget);
      expect(find.text('6 días restantes'), findsOneWidget);
    });

    testWidgets('uses singular days copy when one day remains', (tester) async {
      await _pumpCard(
        tester,
        spentSoFar: 1000,
        referenceDate: DateTime(2026, 9, 29),
      );

      expect(find.text('1 día restante'), findsOneWidget);
    });
  });
}
