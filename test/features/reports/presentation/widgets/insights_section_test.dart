import 'package:biyuya/src/features/reports/domain/entities/insight.dart';
import 'package:biyuya/src/features/reports/presentation/widgets/insights_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

Insight makeInsight({
  int categoryId = 1,
  String categoryName = 'Comida',
  double currentAmount = 600,
  double previousAmount = 480,
  double changePct = 25,
  bool isIncrease = true,
}) {
  return Insight(
    categoryId: categoryId,
    categoryName: categoryName,
    categoryColor: '#4CAF50',
    categoryIcon: '63046',
    currentAmount: currentAmount,
    previousAmount: previousAmount,
    changePct: changePct,
    isIncrease: isIncrease,
  );
}

void main() {
  group('InsightsSection', () {
    testWidgets('renders header and both insight cards', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const InsightsSection(
            insights: [
              Insight(
                categoryId: 1,
                categoryName: 'Comida',
                currentAmount: 600,
                previousAmount: 480,
                changePct: 25,
                isIncrease: true,
              ),
              Insight(
                categoryId: 2,
                categoryName: 'Transporte',
                currentAmount: 240,
                previousAmount: 400,
                changePct: -40,
                isIncrease: false,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Insights del mes'), findsOneWidget);
      expect(find.text('Comida: +25% vs mes anterior'), findsOneWidget);
      expect(find.text('Transporte: -40% vs mes anterior'), findsOneWidget);
      expect(find.text('+25%'), findsOneWidget);
      expect(find.text('-40%'), findsOneWidget);
    });

    testWidgets('renders nothing when list is empty', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const InsightsSection(insights: [])),
      );

      // Empty → SizedBox.shrink: sin header, sin texto, sin cards.
      expect(find.text('Insights del mes'), findsNothing);
      expect(find.byType(InsightCard), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('single insight renders one card only', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: InsightsSection(insights: [makeInsight()])),
      );

      expect(find.byType(InsightCard), findsOneWidget);
      expect(find.textContaining('vs mes anterior'), findsOneWidget);
    });
  });
}
