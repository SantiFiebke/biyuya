import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/views/expense_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/test_helpers.dart';

void main() {
  testWidgets('debug tap', (tester) async {
    await tester.pumpWidget(
      wrapTest(
        child: const ExpenseListView(),
        overrides: [
          categoryControllerProvider.overrideWithValue(
            AsyncData<List<Category>>([
              Category(
                id: 1,
                name: 'Food',
                householdId: 1,
                createdAt: DateTime(2025),
              ),
            ]),
          ),
          expenseControllerProvider.overrideWithValue(
            AsyncData<List<Expense>>([
              Expense(
                id: 1,
                amount: 200,
                date: DateTime(2025, 7, 10),
                description: 'Groceries',
                householdId: 1,
                categoryId: 1,
                createdAt: DateTime(2025, 7, 10),
              ),
            ]),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    debugPrint('chips: ${find.byType(FilterChip).evaluate().length}');
    debugPrint('cat text: ${find.text('Categoría').evaluate().length}');
    await tester.tap(find.byType(FilterChip).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    debugPrint('todas: ${find.text('Todas las categorías').evaluate().length}');
    debugPrint('food: ${find.text('Food').evaluate().length}');

    await tester.tap(find.byType(FilterChip).at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    debugPrint('dialog: ${find.byType(Dialog).evaluate().length}');
    debugPrint('datePicker: ${find.byType(DateRangePickerDialog).evaluate().length}');
  });
}
