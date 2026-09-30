import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:biyuya/src/features/reports/data/repositories/report_repository_impl.dart';
import 'package:biyuya/src/features/reports/domain/repositories/report_repository_base.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../helpers/test_helpers.dart';

/// Records every `getExpensesByMonth` call and serves expenses from a
/// `'year-month'` map; when [failure] is set every month fetch fails.
class _FakeExpenseRepository extends ExpenseRepositoryBase {
  final List<({int householdId, int year, int month})> monthCalls = [];
  final Map<String, List<Expense>> expensesByMonth = <String, List<Expense>>{};
  ExpenseFailure? failure;

  @override
  Future<Result<List<Expense>, ExpenseFailure>> getExpensesByMonth({
    required int householdId,
    required int year,
    required int month,
  }) async {
    monthCalls.add((householdId: householdId, year: year, month: month));
    final failure = this.failure;
    if (failure != null) {
      return Error(failure);
    }
    return Success(expensesByMonth['$year-$month'] ?? const <Expense>[]);
  }

  @override
  Future<Result<List<Expense>, ExpenseFailure>> getExpenses({
    required int householdId,
  }) async => const Error(ExpenseFailure('not used'));

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
  late _FakeExpenseRepository expenseRepo;
  late List<Category> categories;
  late ReportRepositoryImpl repository;

  setUp(() {
    expenseRepo = _FakeExpenseRepository();
    repository = ReportRepositoryImpl(expenseRepo);

    // September 2026 (current month under test).
    expenseRepo.expensesByMonth['2026-9'] = [
      makeExpense(amount: 300, date: DateTime(2026, 9)),
      makeExpense(id: 2, amount: 150, categoryId: 2, date: DateTime(2026, 9)),
    ];
    // August 2026 (previous month rollover).
    expenseRepo.expensesByMonth['2026-8'] = [
      makeExpense(id: 3, amount: 200, date: DateTime(2026, 8)),
    ];

    // Categories are now passed in by the caller (categoriesProvider), no
    // longer fetched by the repository itself.
    categories = [
      makeCategory(name: 'Comida'),
      makeCategory(id: 2, name: 'Transporte'),
    ];
  });

  group('ReportRepositoryImpl.getMonthlyReport', () {
    test(
      'fetches current AND previous month from the expense repository',
      () async {
        final result = await repository.getMonthlyReport(
          householdId: 1,
          year: 2026,
          month: 9,
          categories: categories,
        );

        expect(result.isSuccess(), isTrue);
        expect(
          expenseRepo.monthCalls,
          contains((householdId: 1, year: 2026, month: 9)),
          reason: 'current month must be fetched',
        );
        expect(
          expenseRepo.monthCalls,
          contains((householdId: 1, year: 2026, month: 8)),
          reason: 'previous month rollover must be fetched',
        );
        expect(expenseRepo.monthCalls, hasLength(2));
      },
    );

    test(
      'totals and breakdowns derive from the expense repository data and the '
      'passed categories',
      () async {
        final result = await repository.getMonthlyReport(
          householdId: 1,
          year: 2026,
          month: 9,
          categories: categories,
        );

        expect(result.isSuccess(), isTrue);
        final report = result.when(
          (report) => report,
          (failure) => throw StateError('expected Success, got $failure'),
        );

        expect(report.year, 2026);
        expect(report.month, 9);
        expect(report.total, 450); // 300 + 150
        expect(report.previousTotal, 200); // August
        expect(report.variation, closeTo(125.0, 0.001)); // (450-200)/200*100

        // Sorted by amount desc: Comida (300) then Transporte (150).
        expect(report.categoryBreakdowns, hasLength(2));

        final comida = report.categoryBreakdowns[0];
        expect(comida.categoryId, 1);
        expect(comida.categoryName, 'Comida');
        expect(comida.amount, 300);
        expect(comida.percentage, closeTo(300 / 450 * 100, 0.001));
        expect(comida.previousAmount, 200);

        final transporte = report.categoryBreakdowns[1];
        expect(transporte.categoryId, 2);
        expect(transporte.categoryName, 'Transporte');
        expect(transporte.amount, 150);
        expect(transporte.percentage, closeTo(150 / 450 * 100, 0.001));
        expect(transporte.previousAmount, 0);
      },
    );

    test('expense repository error maps to Error(ReportFailure)', () async {
      expenseRepo.failure = const ExpenseFailure('db exploded');

      final result = await repository.getMonthlyReport(
        householdId: 1,
        year: 2026,
        month: 9,
        categories: categories,
      );

      expect(result.isError(), isTrue);
      final failure = result.when(
        (report) => throw StateError('expected Error, got $report'),
        (failure) => failure,
      );
      expect(failure, isA<ReportFailure>());
      expect(failure.message, contains('db exploded'));
    });
  });
}
