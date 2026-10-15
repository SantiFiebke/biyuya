import 'package:biyuya/src/features/reports/domain/entities/weekly_category_breakdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeeklyCategoryBreakdown.fromBudget', () {
    test('derives weeklyBudget as budgetAmount / 4.33', () {
      final breakdown = WeeklyCategoryBreakdown.fromBudget(
        categoryId: 1,
        categoryName: 'Comida',
        amount: 50,
        budgetAmount: 433,
      );

      expect(breakdown.weeklyBudget, closeTo(100.0, 0.001));
    });

    test('deviation is amount - weeklyBudget', () {
      final breakdown = WeeklyCategoryBreakdown.fromBudget(
        categoryId: 1,
        categoryName: 'Comida',
        amount: 120,
        budgetAmount: 433,
      );

      expect(breakdown.deviation, closeTo(20.0, 0.001));
    });

    test('carries through optional color, icon and isExpense', () {
      final breakdown = WeeklyCategoryBreakdown.fromBudget(
        categoryId: 7,
        categoryName: 'Ahorro',
        amount: 10,
        budgetAmount: 43.3,
        categoryColor: '#00FF00',
        categoryIcon: 'savings',
        isExpense: false,
      );

      expect(breakdown.categoryId, 7);
      expect(breakdown.categoryName, 'Ahorro');
      expect(breakdown.categoryColor, '#00FF00');
      expect(breakdown.categoryIcon, 'savings');
      expect(breakdown.isExpense, isFalse);
    });

    test('classifies status from the derived weekly budget', () {
      final ok = WeeklyCategoryBreakdown.fromBudget(
        categoryId: 1,
        categoryName: 'Comida',
        amount: 50,
        budgetAmount: 433,
      );
      final warning = WeeklyCategoryBreakdown.fromBudget(
        categoryId: 1,
        categoryName: 'Comida',
        amount: 90,
        budgetAmount: 433,
      );
      final exceeded = WeeklyCategoryBreakdown.fromBudget(
        categoryId: 1,
        categoryName: 'Comida',
        amount: 150,
        budgetAmount: 433,
      );

      expect(ok.status, WeeklyBudgetStatus.ok);
      expect(warning.status, WeeklyBudgetStatus.warning);
      expect(exceeded.status, WeeklyBudgetStatus.exceeded);
    });
  });

  group('WeeklyCategoryBreakdown.computeStatus boundaries', () {
    // weeklyBudget = 100 makes the 85% / 100% thresholds exact.
    const budget = 100.0;

    test('amount below 85% is ok', () {
      expect(
        WeeklyCategoryBreakdown.computeStatus(
          amount: 84.99,
          weeklyBudget: budget,
        ),
        WeeklyBudgetStatus.ok,
      );
    });

    test('amount exactly 85% is ok (<= 85%)', () {
      expect(
        WeeklyCategoryBreakdown.computeStatus(
          amount: 85,
          weeklyBudget: budget,
        ),
        WeeklyBudgetStatus.ok,
      );
    });

    test('amount just above 85% is warning', () {
      expect(
        WeeklyCategoryBreakdown.computeStatus(
          amount: 85.0001,
          weeklyBudget: budget,
        ),
        WeeklyBudgetStatus.warning,
      );
    });

    test('amount exactly 100% is warning (<= 100%)', () {
      expect(
        WeeklyCategoryBreakdown.computeStatus(
          amount: 100,
          weeklyBudget: budget,
        ),
        WeeklyBudgetStatus.warning,
      );
    });

    test('amount just above 100% is exceeded', () {
      expect(
        WeeklyCategoryBreakdown.computeStatus(
          amount: 100.0001,
          weeklyBudget: budget,
        ),
        WeeklyBudgetStatus.exceeded,
      );
    });

    test('zero amount is ok', () {
      expect(
        WeeklyCategoryBreakdown.computeStatus(amount: 0, weeklyBudget: budget),
        WeeklyBudgetStatus.ok,
      );
    });

    test('zero budget with any positive amount is exceeded', () {
      expect(
        WeeklyCategoryBreakdown.computeStatus(amount: 1, weeklyBudget: 0),
        WeeklyBudgetStatus.exceeded,
      );
    });
  });
}
