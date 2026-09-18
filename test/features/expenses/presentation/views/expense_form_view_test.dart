import 'dart:async';

import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/views/expense_form_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

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

List<Override> _baseOverrides() => [
  categoryControllerProvider.overrideWithValue(
    AsyncData<List<Category>>(_testCategories),
  ),
  expenseControllerProvider.overrideWithValue(
    const AsyncData<List<Expense>>([]),
  ),
];

/// Fake that auto-submit FAILS so form stays on screen for inspection.
class _FailingExpenseController extends ExpenseController {
  @override
  AsyncValue<List<Expense>> build() => const AsyncData([]);

  @override
  Future<bool> submitExpense({
    required double amount,
    required int categoryId,
    required DateTime date,
    String? description,
    int? expenseId,
  }) async => false;
}

/// Fake that auto-submit SUCCEEDS and navigates away.
class _SuccessExpenseController extends ExpenseController {
  @override
  AsyncValue<List<Expense>> build() => const AsyncData([]);

  @override
  Future<bool> submitExpense({
    required double amount,
    required int categoryId,
    required DateTime date,
    String? description,
    int? expenseId,
  }) async => true;
}

/// Fake that holds loading state until [release] is called.
class _LoadingExpenseController extends ExpenseController {
  final _hold = Completer<void>();

  @override
  AsyncValue<List<Expense>> build() => const AsyncData([]);

  @override
  Future<bool> submitExpense({
    required double amount,
    required int categoryId,
    required DateTime date,
    String? description,
    int? expenseId,
  }) async {
    state = const AsyncLoading();
    await _hold.future;
    state = const AsyncData([]);
    return true;
  }

  void release() => _hold.complete();
}

// Shared controller instance so tests can call release.
late _LoadingExpenseController? _loadingCtrl;

/// GoRouter with a /test route that renders the passed-in [child],
/// and a /home route for navigation assertions.
GoRouter _makeTestRouter(Widget child) => GoRouter(
  initialLocation: '/test',
  routes: [
    GoRoute(path: '/test', builder: (_, _) => child),
    GoRoute(
      path: '/home',
      builder: (_, _) => const Scaffold(body: Text('Home')),
    ),
  ],
);

/// Wrapper with a failing fake: auto-submit runs but fails, form stays.
Widget wrapWithFailing(Widget child) {
  return ProviderScope(
    overrides: [
      categoryControllerProvider.overrideWithValue(
        AsyncData<List<Category>>(_testCategories),
      ),
      expenseControllerProvider.overrideWith(_FailingExpenseController.new),
    ],
    child: MaterialApp.router(routerConfig: _makeTestRouter(child)),
  );
}

/// Wrapper with a successful fake: auto-submit navigates to /home.
Widget wrapWithSuccess(Widget child) {
  return ProviderScope(
    overrides: [
      categoryControllerProvider.overrideWithValue(
        AsyncData<List<Category>>(_testCategories),
      ),
      expenseControllerProvider.overrideWith(_SuccessExpenseController.new),
    ],
    child: MaterialApp.router(routerConfig: _makeTestRouter(child)),
  );
}

/// Wrapper with a controllable loading fake for inspecting loading state.
Widget wrapWithLoading(Widget child) {
  _loadingCtrl = _LoadingExpenseController();
  return ProviderScope(
    overrides: [
      categoryControllerProvider.overrideWithValue(
        AsyncData<List<Category>>(_testCategories),
      ),
      expenseControllerProvider.overrideWith(() => _loadingCtrl!),
    ],
    child: MaterialApp.router(routerConfig: _makeTestRouter(child)),
  );
}

void main() {
  group('ExpenseFormView', () {
    testWidgets('renders create mode with correct title and button', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(child: const ExpenseFormView(), overrides: _baseOverrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nuevo gasto'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('renders edit mode with correct title', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: ExpenseFormView(expense: _testExpense),
          overrides: _baseOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Editar gasto'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('pre-fills amount in edit mode', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: ExpenseFormView(expense: _testExpense),
          overrides: _baseOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      final amountField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(amountField.controller?.text, '150.75');
    });

    testWidgets('shows validation error for empty amount', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ExpenseFormView(), overrides: _baseOverrides()),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresá un monto'), findsOneWidget);
    });

    testWidgets('shows category dropdown', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ExpenseFormView(), overrides: _baseOverrides()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
      expect(find.text('Categoría'), findsOneWidget);
    });

    testWidgets('shows date picker field', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ExpenseFormView(), overrides: _baseOverrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fecha'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows amount field with dollar prefix', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ExpenseFormView(), overrides: _baseOverrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Monto'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('shows description field', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ExpenseFormView(), overrides: _baseOverrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Descripción (opcional)'), findsOneWidget);
    });

    testWidgets('dropdown contains "Crear nueva categoría" option', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(child: const ExpenseFormView(), overrides: _baseOverrides()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      expect(find.text('Crear nueva categoría'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('tapping "Crear nueva categoría" opens BottomSheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(child: const ExpenseFormView(), overrides: _baseOverrides()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear nueva categoría'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva categoría'), findsOneWidget);
    });

    testWidgets('BottomSheet has name input and color picker', (tester) async {
      await tester.pumpWidget(
        wrapTest(child: const ExpenseFormView(), overrides: _baseOverrides()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear nueva categoría'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva categoría'), findsOneWidget);
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);
      expect(find.text('Crear'), findsOneWidget);
    });
  });

  group('ExpenseFormView - deep link', () {
    testWidgets('renders normally when no deep link params provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(child: const ExpenseFormView(), overrides: _baseOverrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nuevo gasto'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsNothing);
    });
  });
}
