import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/features/auth/provider/household_members_provider.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/views/expense_list_view.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalCupertinoLocalizations, GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

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

final _testExpenses = [
  Expense(
    id: 1,
    amount: 200,
    date: DateTime(2025, 7, 10),
    description: 'Groceries',
    householdId: 1,
    categoryId: 1,
    userUuid: 'user-1',
    createdAt: DateTime(2025, 7, 10),
  ),
  Expense(
    id: 2,
    amount: 50,
    date: DateTime(2025, 7, 12),
    description: 'Bus ticket',
    householdId: 1,
    categoryId: 2,
    userUuid: 'user-1',
    createdAt: DateTime(2025, 7, 12),
  ),
];

void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (methodCall) async => null,
        );
  });

  group('ExpenseListView', () {
    testWidgets('shows app bar with title', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gastos'), findsOneWidget);
    });

    testWidgets('displays category filter chip', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNWidgets(2));
      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Fecha'), findsOneWidget);
    });

    testWidgets('tapping category filter opens BottomSheet', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap category filter chip
      await tester.tap(find.text('Categoría'));
      await tester.pumpAndSettle();

      // BottomSheet should show all categories + "all" option
      expect(find.text('Todas las categorías'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('tapping date filter opens date range picker', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap date filter chip
      await tester.tap(find.text('Fecha'));
      await tester.pumpAndSettle();

      // Date range picker dialog should appear
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('shows expense items in list', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Bus ticket'), findsOneWidget);
    });

    testWidgets('shows empty state when no expenses', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              const AsyncData<List<Expense>>([]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay gastos'), findsOneWidget);
      expect(find.text('Registrar gasto'), findsOneWidget);
    });

    testWidgets('shows FAB for creating new expense', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('Member filter chip', () {
    final singleMember = [
      const UserProfile(
        id: 'user-1',
        name: 'Alice',
        lastName: 'Smith',
        householdId: '1',
      ),
    ];

    final twoMembers = [
      const UserProfile(
        id: 'user-1',
        name: 'Alice',
        lastName: 'Smith',
        householdId: '1',
      ),
      const UserProfile(
        id: 'user-2',
        name: 'Bob',
        lastName: 'Jones',
        householdId: '1',
      ),
    ];

    final multiUserExpenses = [
      Expense(
        id: 1,
        amount: 200,
        date: DateTime(2025, 7, 10),
        description: 'Groceries',
        householdId: 1,
        categoryId: 1,
        userUuid: 'user-1',
        createdAt: DateTime(2025, 7, 10),
      ),
      Expense(
        id: 2,
        amount: 50,
        date: DateTime(2025, 7, 12),
        description: 'Bus ticket',
        householdId: 1,
        categoryId: 2,
        userUuid: 'user-2',
        createdAt: DateTime(2025, 7, 12),
      ),
      Expense(
        id: 3,
        amount: 150,
        date: DateTime(2025, 7, 15),
        description: 'Lunch',
        householdId: 1,
        categoryId: 1,
        userUuid: 'user-1',
        createdAt: DateTime(2025, 7, 15),
      ),
    ];

    List<Override> baseOverrides({
      required List<UserProfile> members,
      List<Expense>? expenses,
    }) => [
      categoryControllerProvider.overrideWithValue(
        AsyncData<List<Category>>(_testCategories),
      ),
      expenseControllerProvider.overrideWithValue(
        AsyncData<List<Expense>>(expenses ?? multiUserExpenses),
      ),
      householdMembersProvider.overrideWithValue(
        AsyncData<List<UserProfile>>(members),
      ),
    ];

    testWidgets('hides "Usuario" chip when household has a single member', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: baseOverrides(members: singleMember),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Usuario'), findsNothing);
      expect(find.byType(FilterChip), findsNWidgets(2));
    });

    testWidgets(
      'shows "Usuario" chip when household has more than one member',
      (tester) async {
        await tester.pumpWidget(
          wrapTest(
            child: const ExpenseListView(),
            overrides: baseOverrides(members: twoMembers),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Usuario'), findsOneWidget);
        expect(find.byType(FilterChip), findsNWidgets(3));
      },
    );

    testWidgets('tapping "Usuario" opens bottom sheet with "Todos" + members, '
        'selecting a member filters expenses', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: baseOverrides(members: twoMembers),
        ),
      );
      await tester.pumpAndSettle();

      // All three expenses visible initially
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Bus ticket'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);

      // Open member filter sheet
      await tester.tap(find.text('Usuario'));
      await tester.pumpAndSettle();

      // Sheet shows "Todos" and both member names
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Bob Jones'), findsOneWidget);

      // Select Bob → only his expense remains
      await tester.tap(find.text('Bob Jones'));
      await tester.pumpAndSettle();

      expect(find.text('Bus ticket'), findsOneWidget);
      expect(find.text('Groceries'), findsNothing);
      expect(find.text('Lunch'), findsNothing);

      // Chip label shows selected member name
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('selecting "Todos" clears user filter and shows all expenses', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: baseOverrides(members: twoMembers),
        ),
      );
      await tester.pumpAndSettle();

      // Filter to Alice first
      await tester.tap(find.text('Usuario'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice Smith'));
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Bus ticket'), findsNothing);

      // Reopen sheet and select "Todos"
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();

      // All expenses visible again
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Bus ticket'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('changing members to single member clears the user filter', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: baseOverrides(members: twoMembers),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              ...GlobalCupertinoLocalizations.delegates,
              ...GlobalMaterialLocalizations.delegates,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: [Locale('es', 'AR')],
            home: Scaffold(body: ExpenseListView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Filter to user-2
      await tester.tap(find.text('Usuario'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob Jones'));
      await tester.pumpAndSettle();

      expect(find.text('Bus ticket'), findsOneWidget);

      // Simulate member list shrinking to 1 by overriding the provider
      container.updateOverrides([
        categoryControllerProvider.overrideWithValue(
          AsyncData<List<Category>>(_testCategories),
        ),
        expenseControllerProvider.overrideWithValue(
          AsyncData<List<Expense>>(multiUserExpenses),
        ),
        householdMembersProvider.overrideWithValue(
          AsyncData<List<UserProfile>>(singleMember),
        ),
      ]);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Filter cleared → all expenses shown again
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Bus ticket'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
    });
  });

  group('ExpenseTile actions menu', () {
    List<Override> baseOverrides({
      List<Expense>? expenses,
      ExpenseController Function()? controller,
    }) => [
      categoryControllerProvider.overrideWithValue(
        AsyncData<List<Category>>(_testCategories),
      ),
      if (controller != null)
        expenseControllerProvider.overrideWith(controller)
      else
        expenseControllerProvider.overrideWithValue(
          AsyncData<List<Expense>>(expenses ?? _testExpenses),
        ),
    ];

    testWidgets('shows edit and delete menu items', (tester) async {
      final fake = _RecordingExpenseController(_testExpenses);
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: baseOverrides(controller: () => fake),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Más opciones'), findsWidgets);
      expect(find.byIcon(Icons.more_vert), findsWidgets);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('tapping delete opens confirmation dialog', (tester) async {
      final fake = _RecordingExpenseController(_testExpenses);
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: baseOverrides(controller: () => fake),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar gasto'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Eliminar'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancelar'), findsOneWidget);
    });

    testWidgets('confirming delete records id and removes expense', (
      tester,
    ) async {
      final fake = _RecordingExpenseController(_testExpenses);
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: baseOverrides(controller: () => fake),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(fake.deletedIds, [1]);
      expect(find.text('Groceries'), findsNothing);
      expect(find.text('Bus ticket'), findsOneWidget);
    });

    testWidgets('cancelling delete records nothing', (tester) async {
      final fake = _RecordingExpenseController(_testExpenses);
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: baseOverrides(controller: () => fake),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(fake.deletedIds, isEmpty);
      expect(find.text('Groceries'), findsOneWidget);
    });
  });
}

class _RecordingExpenseController extends ExpenseController {
  _RecordingExpenseController(this._initial);

  final List<Expense> _initial;
  final List<int> deletedIds = [];

  @override
  AsyncValue<List<Expense>> build() => AsyncData(_initial);

  @override
  Future<bool> deleteExpense({required int id}) async {
    deletedIds.add(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
    return true;
  }
}
