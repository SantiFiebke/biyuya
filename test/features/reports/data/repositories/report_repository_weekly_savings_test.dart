import 'package:biyuya/src/features/categories/data/local/category_cache.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:biyuya/src/features/reports/data/repositories/report_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/test_helpers.dart';

/// Serves all expenses from [allExpenses] for `getExpenses` and from a
/// `'year-month'` map for `getExpensesByMonth`.
class _FakeExpenseRepository extends ExpenseRepositoryBase {
  List<Expense> allExpenses = const [];
  final Map<String, List<Expense>> expensesByMonth = <String, List<Expense>>{};

  @override
  Future<Result<List<Expense>, ExpenseFailure>> getExpenses({
    required int householdId,
  }) async => Success(allExpenses);

  @override
  Future<Result<List<Expense>, ExpenseFailure>> getExpensesByMonth({
    required int householdId,
    required int year,
    required int month,
  }) async => Success(expensesByMonth['$year-$month'] ?? const <Expense>[]);

  @override
  Future<Result<Expense, ExpenseFailure>> createExpense({
    required double amount,
    required DateTime date,
    required int householdId,
    required int categoryId,
    required String userUuid,
    String? description,
    String? clientId,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Expense, ExpenseFailure>> updateExpense({
    required int id,
    required double amount,
    required DateTime date,
    required int categoryId,
    String? description,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void, ExpenseFailure>> deleteExpense({required int id}) async =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeExpenseRepository expenseRepo;
  late ReportRepositoryImpl repository;
  late List<Category> categories;

  setUp(() {
    expenseRepo = _FakeExpenseRepository();
    repository = ReportRepositoryImpl(expenseRepo);
    categories = [makeCategory(name: 'Comida')];
  });

  group('ReportRepositoryImpl.getWeeklyReport variation', () {
    // Monday 2026-09-07; week = [09-07, 09-14), previous = [08-31, 09-07).
    final weekStart = DateTime(2026, 9, 7);

    test(
      'variation is (total - previousWeekTotal) / previousWeekTotal * 100',
      () async {
        expenseRepo.allExpenses = [
          makeExpense(amount: 300, date: DateTime(2026, 9, 7)),
          makeExpense(id: 2, date: DateTime(2026, 9, 8)),
          makeExpense(id: 3, amount: 200, date: DateTime(2026, 9)),
        ];

        final result = await repository.getWeeklyReport(
          householdId: 1,
          weekStart: weekStart,
          categories: categories,
        );

        expect(result.isSuccess(), isTrue);
        final report = result.when(
          (report) => report,
          (failure) => throw StateError('expected Success, got $failure'),
        );

        expect(report.total, 400); // 300 + 100
        expect(report.previousWeekTotal, 200);
        expect(report.variation, closeTo(100.0, 0.001)); // (400-200)/200*100
        expect(report.weekEnd, DateTime(2026, 9, 14));
        expect(report.year, 2026);
      },
    );

    test('variation is 0 when previousWeekTotal is 0', () async {
      expenseRepo.allExpenses = [
        makeExpense(amount: 300, date: DateTime(2026, 9, 7)),
      ];

      final result = await repository.getWeeklyReport(
        householdId: 1,
        weekStart: weekStart,
        categories: categories,
      );

      final report = result.when(
        (report) => report,
        (failure) => throw StateError('expected Success, got $failure'),
      );

      expect(report.previousWeekTotal, 0);
      expect(report.variation, 0.0);
      expect(report.hasPreviousData, isFalse);
    });
  });

  group('ReportRepositoryImpl.getSavingsReport', () {
    // Expense category (counts toward the goal) and a non-expense savings
    // category (its movements are the saved total).
    final expenseCategory = makeCategory(name: 'Comida');
    final savingsCategory = makeCategory(
      id: 2,
      name: 'Ahorro',
      isExpense: false,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await const CategoryCache().save([expenseCategory, savingsCategory]);
    });

    test('goalAmount is 3 * average monthly expenses over 3 months', () async {
      // Countable expenses: Sep 300, Aug 200, Jul 100 → window 600,
      // average 200, goal 600.
      expenseRepo.expensesByMonth['2026-9'] = [
        makeExpense(amount: 300, date: DateTime(2026, 9, 5)),
        makeExpense(
          id: 2,
          categoryId: 2,
          date: DateTime(2026, 9, 6),
        ),
      ];
      expenseRepo.expensesByMonth['2026-8'] = [
        makeExpense(id: 3, amount: 200, date: DateTime(2026, 8, 5)),
      ];
      expenseRepo.expensesByMonth['2026-7'] = [
        makeExpense(id: 4, date: DateTime(2026, 7, 5)),
      ];

      final result = await repository.getSavingsReport(
        householdId: 1,
        year: 2026,
        month: 9,
      );

      expect(result.isSuccess(), isTrue);
      final report = result.when(
        (report) => report,
        (failure) => throw StateError('expected Success, got $failure'),
      );

      expect(report.goalAmount, closeTo(600.0, 0.001));
      expect(report.totalSaved, 100); // only the non-expense category
      expect(report.progressPct, closeTo(100 / 600 * 100, 0.001));
      expect(report.entries, hasLength(1));
      expect(report.entries.single.source, 'Ahorro');
    });

    test('progressPct is 0 when goalAmount is 0', () async {
      // Only savings movements, no countable expenses → goal 0.
      expenseRepo.expensesByMonth['2026-9'] = [
        makeExpense(categoryId: 2, date: DateTime(2026, 9, 6)),
      ];

      final result = await repository.getSavingsReport(
        householdId: 1,
        year: 2026,
        month: 9,
      );

      final report = result.when(
        (report) => report,
        (failure) => throw StateError('expected Success, got $failure'),
      );

      expect(report.goalAmount, 0.0);
      expect(report.totalSaved, 100);
      expect(report.progressPct, 0.0);
    });
  });
}
