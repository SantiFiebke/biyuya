import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/views/expense_form_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _testExpense = Expense(
  id: 42,
  amount: 150.75,
  date: DateTime(2025, 6, 15),
  description: 'Groceries',
  householdId: 1,
  categoryId: 2,
  userUuid: 'user-1',
  createdAt: DateTime(2025, 6, 15),
);

final _testCategories = [
  Category(
    id: 1,
    name: 'Food',
    householdId: 1,
    createdAt: DateTime(2025),
    color: '#4CAF50',
    icon: '63046',
  ),
  Category(
    id: 2,
    name: 'Transport',
    householdId: 1,
    createdAt: DateTime(2025),
    color: '#2196F3',
    icon: '57681',
  ),
];

Widget wrap(Widget child) {
  return ProviderScope(
    overrides: [
      categoryControllerProvider.overrideWithValue(
        AsyncData<List<Category>>(_testCategories),
      ),
      expenseControllerProvider.overrideWithValue(const AsyncData<List<Expense>>([])),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('ExpenseFormView', () {
    testWidgets('renders create mode with correct title and button', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const ExpenseFormView()));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo gasto'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('renders edit mode with correct title', (tester) async {
      await tester.pumpWidget(wrap(ExpenseFormView(expense: _testExpense)));
      await tester.pumpAndSettle();

      expect(find.text('Editar gasto'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('pre-fills amount in edit mode', (tester) async {
      await tester.pumpWidget(wrap(ExpenseFormView(expense: _testExpense)));
      await tester.pumpAndSettle();

      // Amount field is the first TextFormField (has attach_money icon)
      final amountField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(amountField.controller?.text, '150.75');
    });

    testWidgets('shows validation error for empty amount', (tester) async {
      await tester.pumpWidget(wrap(const ExpenseFormView()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresá un monto'), findsOneWidget);
    });

    testWidgets('shows category dropdown', (tester) async {
      await tester.pumpWidget(wrap(const ExpenseFormView()));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
      expect(find.text('Categoría'), findsOneWidget);
    });

    testWidgets('shows date picker field', (tester) async {
      await tester.pumpWidget(wrap(const ExpenseFormView()));
      await tester.pumpAndSettle();

      expect(find.text('Fecha'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows amount field with dollar prefix', (tester) async {
      await tester.pumpWidget(wrap(const ExpenseFormView()));
      await tester.pumpAndSettle();

      expect(find.text('Monto'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('shows description field', (tester) async {
      await tester.pumpWidget(wrap(const ExpenseFormView()));
      await tester.pumpAndSettle();

      expect(find.text('Descripción (opcional)'), findsOneWidget);
    });

    testWidgets(
      'dropdown contains "Crear nueva categoría" option',
      (tester) async {
        await tester.pumpWidget(wrap(const ExpenseFormView()));
        await tester.pumpAndSettle();

        // Open the dropdown
        await tester.tap(find.byType(DropdownButtonFormField<int>));
        await tester.pumpAndSettle();

        expect(find.text('Crear nueva categoría'), findsOneWidget);
        expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      },
    );

    testWidgets(
      'tapping "Crear nueva categoría" opens BottomSheet',
      (tester) async {
        await tester.pumpWidget(wrap(const ExpenseFormView()));
        await tester.pumpAndSettle();

        // Open dropdown then tap "Crear nueva categoría"
        await tester.tap(find.byType(DropdownButtonFormField<int>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Crear nueva categoría'));
        await tester.pumpAndSettle();

        expect(find.text('Nueva categoría'), findsOneWidget);
      },
    );

    testWidgets(
      'BottomSheet has name input and color picker',
      (tester) async {
        await tester.pumpWidget(wrap(const ExpenseFormView()));
        await tester.pumpAndSettle();

        // Open dropdown then tap "Crear nueva categoría"
        await tester.tap(find.byType(DropdownButtonFormField<int>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Crear nueva categoría'));
        await tester.pumpAndSettle();

        // BottomSheet content
        expect(find.text('Nueva categoría'), findsOneWidget);
        expect(find.text('Nombre'), findsOneWidget);
        // Color picker: multiple colored circles via GestureDetector
        expect(find.byType(GestureDetector), findsWidgets);
        expect(find.text('Crear'), findsOneWidget);
      },
    );
  });
}
