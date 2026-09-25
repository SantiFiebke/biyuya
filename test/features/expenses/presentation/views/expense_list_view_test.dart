import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/core/presentation/utils/date_utils.dart';
import 'package:biyuya/src/core/presentation/widgets/duplicate_warning_badge.dart';
import 'package:biyuya/src/core/presentation/widgets/pending_badge.dart';
import 'package:biyuya/src/features/auth/provider/household_members_provider.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_list_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/views/expense_list_view.dart';
import 'package:biyuya/src/features/settings/domain/entities/user_settings.dart';
import 'package:biyuya/src/features/settings/presentation/controllers/settings_controller.dart';
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

// Bypasses SettingsController.build() _load (hits Supabase otherwise).
Override _settingsOverride({bool enabled = true}) => settingsControllerProvider
    .overrideWithValue(AsyncData(UserSettings(debtSettlementEnabled: enabled)));

// Real householdMembersProvider pulls authSession -> Supabase in tests.
Override _emptyMembersOverride() => householdMembersProvider.overrideWithValue(
  const AsyncData<List<UserProfile>>([]),
);

/// In-memory stand-in for the paginated controller: applies filters against
/// the source list the way the server would, so server-side filtering is
/// observable in widget tests without touching Supabase.
///
/// Holds the caller's list by reference so a shared fake (delete tests) can
/// mutate it and `refresh()` re-reads the change.
class _FakeExpenseListController extends ExpenseListController {
  _FakeExpenseListController(this._source);

  final List<Expense> _source;
  int? _categoryId;
  String? _userUuid;
  DateTime? _startDate;
  DateTime? _endDate;

  /// When true, [loadMore] flips `isLoadingMore` (footer spinner) and keeps it
  /// until the next refresh, so tests can observe the loading state.
  bool simulateLoadMore = false;

  int loadMoreCalls = 0;

  List<Expense> _filtered() => _source.where((e) {
    if (_categoryId != null && e.categoryId != _categoryId) {
      return false;
    }
    if (_userUuid != null && e.userUuid != _userUuid) {
      return false;
    }
    if (_startDate != null && e.date.isBefore(_startDate!)) {
      return false;
    }
    if (_endDate != null && e.date.isAfter(_endDate!)) {
      return false;
    }
    return true;
  }).toList();

  @override
  ExpenseListState build() => ExpenseListState(items: _filtered());

  @override
  Future<void> refresh() async {
    state = ExpenseListState(items: _filtered());
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls++;
    if (simulateLoadMore) {
      state = state.copyWith(isLoadingMore: true);
    }
  }

  @override
  Future<void> setFilters({
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? userUuid,
    bool clearCategory = false,
    bool clearDates = false,
    bool clearUser = false,
  }) async {
    if (clearCategory) {
      _categoryId = null;
    } else if (categoryId != null) {
      _categoryId = categoryId;
    }
    if (clearDates) {
      _startDate = null;
      _endDate = null;
    } else {
      _startDate = startDate ?? _startDate;
      _endDate = endDate ?? _endDate;
    }
    if (clearUser) {
      _userUuid = null;
    } else if (userUuid != null) {
      _userUuid = userUuid;
    }
    state = ExpenseListState(items: _filtered());
  }

  @override
  Future<void> clearFilters() =>
      setFilters(clearCategory: true, clearDates: true, clearUser: true);
}

Override _listOverride(List<Expense> expenses) => expenseListControllerProvider
    .overrideWith(() => _FakeExpenseListController(expenses));

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
            _listOverride(_testExpenses),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
            _settingsOverride(),
            _emptyMembersOverride(),
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
            _listOverride(_testExpenses),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
            _settingsOverride(),
            _emptyMembersOverride(),
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
            _listOverride(_testExpenses),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
            _settingsOverride(),
            _emptyMembersOverride(),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap category filter chip
      await tester.tap(find.text('Categoría'));
      await tester.pumpAndSettle();

      // BottomSheet should show all categories + "all" option
      expect(find.text('Todas las categorías'), findsOneWidget);
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Food')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Transport')),
        findsOneWidget,
      );
    });

    testWidgets('tapping date filter opens date range picker', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            _listOverride(_testExpenses),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
            _settingsOverride(),
            _emptyMembersOverride(),
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
            _listOverride(_testExpenses),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
            _settingsOverride(),
            _emptyMembersOverride(),
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
            _listOverride(const []),
            expenseControllerProvider.overrideWithValue(
              const AsyncData<List<Expense>>([]),
            ),
            _settingsOverride(),
            _emptyMembersOverride(),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Todavía no hay gastos'), findsOneWidget);
      expect(find.text('Registrar gasto'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Registrar gasto'),
        findsOneWidget,
      );
    });

    testWidgets('shows FAB for creating new expense', (tester) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            _listOverride(_testExpenses),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
            _settingsOverride(),
            _emptyMembersOverride(),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('scrolling to the bottom triggers loadMore footer spinner', (
      tester,
    ) async {
      // Enough rows to overflow the viewport so a drag actually scrolls.
      final many = List.generate(
        20,
        (i) => Expense(
          id: i + 1,
          amount: 10,
          date: DateTime(2025, 7, (i % 28) + 1),
          description: 'Item $i',
          householdId: 1,
          categoryId: 1,
          userUuid: 'user-1',
          createdAt: DateTime(2025, 7),
        ),
      );

      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            expenseListControllerProvider.overrideWith(
              () => _FakeExpenseListController(many)..simulateLoadMore = true,
            ),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(many),
            ),
            _settingsOverride(),
            _emptyMembersOverride(),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Drag to the end: ScrollController listener fires loadMore near bottom.
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      // Indeterminate spinner never settles: pump frames manually.
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('"Liquidar deudas" opens debt settlement sheet', (
      tester,
    ) async {
      final now = DateTime.now();
      final currentMonthExpenses = [
        Expense(
          id: 1,
          amount: 200,
          date: now,
          description: 'Groceries',
          householdId: 1,
          categoryId: 1,
          userUuid: 'user-1',
          createdAt: now,
        ),
        Expense(
          id: 2,
          amount: 50,
          date: now,
          description: 'Bus ticket',
          householdId: 1,
          categoryId: 2,
          userUuid: 'user-2',
          createdAt: now,
        ),
      ];
      const members = [
        UserProfile(
          id: 'user-1',
          name: 'Alice',
          lastName: 'Smith',
          householdId: '1',
        ),
        UserProfile(
          id: 'user-2',
          name: 'Bob',
          lastName: 'Jones',
          householdId: '1',
        ),
      ];

      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            _listOverride(currentMonthExpenses),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(currentMonthExpenses),
            ),
            householdMembersProvider.overrideWithValue(
              const AsyncData<List<UserProfile>>(members),
            ),
            _settingsOverride(),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Liquidar deudas'), findsOneWidget);

      await tester.tap(find.text('Liquidar deudas'));
      await tester.pumpAndSettle();

      expect(find.text('Liquidación de deudas'), findsOneWidget);
    });

    testWidgets('"Liquidar deudas" hidden when debt settlement is disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            _listOverride(_testExpenses),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>(_testExpenses),
            ),
            householdMembersProvider.overrideWithValue(
              const AsyncData<List<UserProfile>>([
                UserProfile(
                  id: 'user-1',
                  name: 'Alice',
                  lastName: 'Smith',
                  householdId: '1',
                ),
              ]),
            ),
            _settingsOverride(enabled: false),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Liquidar deudas'), findsNothing);
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
      _listOverride(expenses ?? multiUserExpenses),
      expenseControllerProvider.overrideWithValue(
        AsyncData<List<Expense>>(expenses ?? multiUserExpenses),
      ),
      householdMembersProvider.overrideWithValue(
        AsyncData<List<UserProfile>>(members),
      ),
      _settingsOverride(),
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

      // Select Bob → only his expense remains (server-side filter via fake)
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

      // Simulate member list shrinking to 1 by overriding the providers.
      // Fresh list-controller fake: unfiltered source, filter cleared.
      container.updateOverrides([
        categoryControllerProvider.overrideWithValue(
          AsyncData<List<Category>>(_testCategories),
        ),
        _listOverride(multiUserExpenses),
        expenseControllerProvider.overrideWithValue(
          AsyncData<List<Expense>>(multiUserExpenses),
        ),
        householdMembersProvider.overrideWithValue(
          const AsyncData<List<UserProfile>>([
            UserProfile(
              id: 'user-1',
              name: 'Alice',
              lastName: 'Smith',
              householdId: '1',
            ),
          ]),
        ),
        _settingsOverride(),
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
      required List<Expense> source,
      required ExpenseController Function() controller,
    }) => [
      categoryControllerProvider.overrideWithValue(
        AsyncData<List<Category>>(_testCategories),
      ),
      // Same source instance: the recording controller mutates it on delete
      // and the list fake re-reads it on the view's post-delete refresh().
      _listOverride(source),
      expenseControllerProvider.overrideWith(controller),
      _settingsOverride(),
      _emptyMembersOverride(),
    ];

    testWidgets('shows edit and delete menu items', (tester) async {
      final source = List<Expense>.of(_testExpenses);
      final fake = _RecordingExpenseController(source);
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: baseOverrides(source: source, controller: () => fake),
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
      final source = List<Expense>.of(_testExpenses);
      final fake = _RecordingExpenseController(source);
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: baseOverrides(source: source, controller: () => fake),
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
      final source = List<Expense>.of(_testExpenses);
      final fake = _RecordingExpenseController(source);
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: baseOverrides(source: source, controller: () => fake),
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
      final source = List<Expense>.of(_testExpenses);
      final fake = _RecordingExpenseController(source);
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: baseOverrides(source: source, controller: () => fake),
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

  group('Pending sync UI', () {
    final syncedExpense = Expense(
      id: 1,
      amount: 200,
      date: DateTime(2025, 7, 10),
      description: 'Synced',
      householdId: 1,
      categoryId: 1,
      userUuid: 'user-1',
      createdAt: DateTime(2025, 7, 10),
    );
    final pendingExpense = Expense(
      id: 2,
      amount: 50,
      date: DateTime(2025, 7, 12),
      description: 'Pending',
      householdId: 1,
      categoryId: 2,
      userUuid: 'user-1',
      clientId: 'client-2',
      syncStatus: ExpenseSyncStatus.pending,
      createdAt: DateTime(2025, 7, 12),
    );

    List<Override> overrides(List<Expense> expenses) => [
      categoryControllerProvider.overrideWithValue(
        AsyncData<List<Category>>(_testCategories),
      ),
      _listOverride(expenses),
      expenseControllerProvider.overrideWithValue(
        AsyncData<List<Expense>>(expenses),
      ),
      _settingsOverride(),
      _emptyMembersOverride(),
    ];

    testWidgets('shows PendingBadge only for the non-synced expense', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: overrides([syncedExpense, pendingExpense]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PendingBadge), findsOneWidget);
      expect(find.text('pendiente'), findsOneWidget);
    });

    testWidgets('shows no PendingBadge when all expenses are synced', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: overrides([syncedExpense]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PendingBadge), findsNothing);
      expect(find.text('pendiente'), findsNothing);
    });

    testWidgets('shows "Reintentar sync" when a pending expense exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: overrides([syncedExpense, pendingExpense]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reintentar sync'), findsOneWidget);
    });

    testWidgets('hides "Reintentar sync" when all expenses are synced', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: overrides([syncedExpense]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reintentar sync'), findsNothing);
    });
  });

  group('ExpenseListTile small-screen layout regression', () {
    final worstCaseExpense = Expense(
      id: 99,
      amount: 1234567.89,
      date: DateTime(2025, 7, 10),
      description:
          'Compra muy larga en el supermercado con descripción extensa que debe truncarse',
      householdId: 1,
      categoryId: 1,
      userUuid: 'user-1',
      clientId: 'client-99',
      syncStatus: ExpenseSyncStatus.pending,
      createdAt: DateTime(2025, 7, 10),
    );

    final worstCaseCategory = Category(
      id: 1,
      name: 'Supermercado y almacén',
      householdId: 1,
      createdAt: DateTime(2025),
      color: '#4CAF50',
      icon: '63046',
    );

    for (final width in [320.0, 360.0, 411.0]) {
      testWidgets(
        'does not overflow at ${width.toInt()}px with badges in subtitle',
        (tester) async {
          tester.view.physicalSize = Size(width, 640);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapTest(
              child: ExpenseListTile(
                expense: worstCaseExpense,
                category: worstCaseCategory,
                isDuplicate: true,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(find.byType(PendingBadge), findsOneWidget);
          expect(find.byType(DuplicateWarningBadge), findsOneWidget);
        },
      );
    }
  });

  group('ExpenseListTile long category subtitle regression', () {
    const longCategoryName =
        'Supermercado y almacén con un nombre extremadamente largo que no cabe';

    final longCategory = Category(
      id: 1,
      name: longCategoryName,
      householdId: 1,
      createdAt: DateTime(2025),
      color: '#4CAF50',
      icon: '63046',
    );

    final worstCaseExpense = Expense(
      id: 99,
      amount: 1234567.89,
      date: DateTime(2025, 7, 10),
      description:
          'Compra muy larga en el supermercado con descripción extensa que debe truncarse',
      householdId: 1,
      categoryId: 1,
      userUuid: 'user-1',
      clientId: 'client-99',
      syncStatus: ExpenseSyncStatus.pending,
      createdAt: DateTime(2025, 7, 10),
    );

    for (final width in [320.0, 360.0]) {
      testWidgets(
        'keeps long category on one line and date visible at ${width.toInt()}px',
        (tester) async {
          tester.view.physicalSize = Size(width, 640);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapTest(
              child: ExpenseListTile(
                expense: worstCaseExpense,
                category: longCategory,
                isDuplicate: true,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);

          final subtitle =
              '$longCategoryName · ${formatHumanDate(worstCaseExpense.date)}';
          final subtitleText = tester.widget<Text>(find.text(subtitle));
          expect(subtitleText.maxLines, 1);
          expect(subtitleText.overflow, TextOverflow.ellipsis);

          expect(
            tester.getSize(find.byType(ListTile).first).height,
            lessThan(150),
          );
        },
      );
    }
  });

  group('Duplicate warning badge', () {
    // Two content-duplicates (same amount/day/category/description) + one
    // unique expense.
    final duplicateA = Expense(
      id: 1,
      amount: 200,
      date: DateTime(2025, 7, 10),
      description: 'Groceries',
      householdId: 1,
      categoryId: 1,
      userUuid: 'user-1',
      createdAt: DateTime(2025, 7, 10),
    );
    final duplicateB = Expense(
      id: 2,
      amount: 200,
      date: DateTime(2025, 7, 10),
      description: 'Groceries',
      householdId: 1,
      categoryId: 1,
      userUuid: 'user-1',
      createdAt: DateTime(2025, 7, 10),
    );
    final unique = Expense(
      id: 3,
      amount: 50,
      date: DateTime(2025, 7, 12),
      description: 'Bus ticket',
      householdId: 1,
      categoryId: 2,
      userUuid: 'user-1',
      createdAt: DateTime(2025, 7, 12),
    );

    testWidgets('shows badge for duplicates only, not for unique expense', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapTest(
          child: const ExpenseListView(),
          overrides: [
            categoryControllerProvider.overrideWithValue(
              AsyncData<List<Category>>(_testCategories),
            ),
            _listOverride([duplicateA, duplicateB, unique]),
            expenseControllerProvider.overrideWithValue(
              AsyncData<List<Expense>>([duplicateA, duplicateB, unique]),
            ),
            _settingsOverride(),
            _emptyMembersOverride(),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DuplicateWarningBadge), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.widgetWithText(ExpenseListTile, 'Groceries'),
          matching: find.byType(DuplicateWarningBadge),
        ),
        findsNWidgets(2),
      );
      expect(
        find.descendant(
          of: find.widgetWithText(ExpenseListTile, 'Bus ticket'),
          matching: find.byType(DuplicateWarningBadge),
        ),
        findsNothing,
      );
    });
  });
}

class _RecordingExpenseController extends ExpenseController {
  _RecordingExpenseController(this.source);

  /// Shared with the list fake: deleting mutates the same list the paginated
  /// controller re-reads on the view's post-delete refresh().
  final List<Expense> source;
  final List<int> deletedIds = [];

  @override
  AsyncValue<List<Expense>> build() => AsyncData(List.of(source));

  @override
  Future<bool> deleteExpense({required int id}) async {
    deletedIds.add(id);
    source.removeWhere((e) => e.id == id);
    state = AsyncData(List.of(source));
    return true;
  }
}
