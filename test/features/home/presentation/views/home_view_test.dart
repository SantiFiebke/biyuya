import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/core/presentation/utils/date_utils.dart';
import 'package:biyuya/src/core/presentation/widgets/duplicate_warning_badge.dart';
import 'package:biyuya/src/core/presentation/widgets/pending_badge.dart';
import 'package:biyuya/src/features/auth/domain/entities/household_data.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/household_members_provider.dart';
import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/home/presentation/views/home_view.dart';
import 'package:biyuya/src/features/home/presentation/widgets/first_steps_checklist.dart';
import 'package:biyuya/src/features/home/presentation/widgets/month_projection_card.dart';
import 'package:biyuya/src/features/settings/domain/entities/user_settings.dart';
import 'package:biyuya/src/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/test_helpers.dart';

class FakeHouseholdName extends HouseholdName {
  HouseholdData? data;

  @override
  Future<HouseholdData?> build() async => data;
}

const _singleMember = UserProfile(
  id: 'test-user-id',
  name: 'Test',
  lastName: 'User',
  householdId: '1',
);

const List<UserProfile> _twoMembers = [
  _singleMember,
  UserProfile(
    id: 'other-user-id',
    name: 'Other',
    lastName: 'User',
    householdId: '1',
  ),
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<Override> _baseOverrides({
  HouseholdData? householdData = const HouseholdData(name: 'Mi Hogar'),
  List<Expense> expenses = const [],
  List<Category> categories = const [],
  UserSettings settings = const UserSettings(),
  List<UserProfile> members = const [_singleMember],
}) {
  final fakeNotifier = FakeHouseholdName()..data = householdData;
  return [
    authSessionControllerProvider.overrideWith(FakeAuthSessionController.new),
    expenseControllerProvider.overrideWithValue(
      AsyncData<List<Expense>>(expenses),
    ),
    categoryControllerProvider.overrideWithValue(
      AsyncData<List<Category>>(categories),
    ),
    householdNameProvider.overrideWith(() => fakeNotifier),
    // keepAlive + hits authRepository (Supabase) otherwise.
    householdMembersProvider.overrideWithValue(
      AsyncData<List<UserProfile>>(members),
    ),
    // Bypasses SettingsController.build() _load (hits Supabase otherwise).
    settingsControllerProvider.overrideWithValue(AsyncData(settings)),
  ];
}

Future<void> _pumpHome(
  WidgetTester tester, {
  List<Override>? overrides,
  Size size = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    wrapTest(child: const HomeView(), overrides: overrides ?? _baseOverrides()),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('HomeView', () {
    testWidgets('renders app bar title', (tester) async {
      await _pumpHome(tester);

      expect(find.text('Biyuya - Cuentas claras'), findsOneWidget);
    });

    testWidgets('balance card shows monthly label and amount', (tester) async {
      final expenses = [makeExpense(date: DateTime.now())];

      await _pumpHome(tester, overrides: _baseOverrides(expenses: expenses));

      expect(find.text('Gastado este mes'), findsOneWidget);
      expect(find.textContaining('100,00', findRichText: true), findsWidgets);
    });

    testWidgets('renders month projection card when enabled', (tester) async {
      await _pumpHome(
        tester,
        overrides: _baseOverrides(
          settings: const UserSettings(monthProjectionEnabled: true),
        ),
      );

      expect(find.text('Proyección fin de mes'), findsOneWidget);
    });

    testWidgets('hides month projection card when disabled', (tester) async {
      await _pumpHome(tester);

      expect(find.text('Proyección fin de mes'), findsNothing);
      expect(find.byType(MonthProjectionCard), findsNothing);
    });

    testWidgets('renders quick actions', (tester) async {
      await _pumpHome(tester);

      expect(find.text('Nuevo gasto'), findsOneWidget);
      expect(find.text('Reportes'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget);
    });

    testWidgets('shows recent movements when there are expenses', (
      tester,
    ) async {
      final expenses = [
        makeExpense(description: 'Groceries'),
        makeExpense(id: 2, description: 'Bus ticket'),
      ];

      await _pumpHome(tester, overrides: _baseOverrides(expenses: expenses));

      expect(find.text('Últimos movimientos'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Bus ticket'), findsOneWidget);
    });

    testWidgets('shows empty state when there are no expenses', (tester) async {
      await _pumpHome(tester);

      expect(find.text('Todavía no hay gastos'), findsOneWidget);
    });

    testWidgets('shows pending badge only for non-synced recent expense', (
      tester,
    ) async {
      final expenses = [
        makeExpense(description: 'Synced'),
        makeExpense(
          id: 2,
          description: 'Pending',
          syncStatus: ExpenseSyncStatus.pending,
        ),
      ];

      await _pumpHome(tester, overrides: _baseOverrides(expenses: expenses));

      expect(find.text('pendiente'), findsOneWidget);
    });

    testWidgets('shows no pending badge when all recent expenses are synced', (
      tester,
    ) async {
      final expenses = [
        makeExpense(description: 'Synced'),
        makeExpense(id: 2, description: 'Also synced'),
      ];

      await _pumpHome(tester, overrides: _baseOverrides(expenses: expenses));

      expect(find.text('pendiente'), findsNothing);
    });

    testWidgets('shows duplicate badge for duplicate recent items only', (
      tester,
    ) async {
      // Same amount/day/category/description → ids 1 & 2 duplicate; 3 unique.
      final expenses = [
        makeExpense(description: 'Groceries'),
        makeExpense(id: 2, description: 'Groceries'),
        makeExpense(id: 3, description: 'Bus ticket'),
      ];

      await _pumpHome(tester, overrides: _baseOverrides(expenses: expenses));

      expect(find.byType(DuplicateWarningBadge), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Groceries'),
          matching: find.byType(DuplicateWarningBadge),
        ),
        findsNWidgets(2),
      );
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Bus ticket'),
          matching: find.byType(DuplicateWarningBadge),
        ),
        findsNothing,
      );
    });
  });

  group('HomeView small-screen layout regression', () {
    final worstCase = makeExpense(
      amount: 1234567.89,
      description:
          'Compra muy larga en el supermercado con descripción extensa que debe truncarse',
      syncStatus: ExpenseSyncStatus.pending,
    );
    final duplicate = makeExpense(
      id: 2,
      amount: 1234567.89,
      description:
          'Compra muy larga en el supermercado con descripción extensa que debe truncarse',
      syncStatus: ExpenseSyncStatus.pending,
    );
    final category = makeCategory(name: 'Supermercado y almacén');

    for (final width in [320.0, 360.0, 411.0]) {
      testWidgets(
        'does not overflow at ${width.toInt()}px with badges in subtitle',
        (tester) async {
          await _pumpHome(
            tester,
            size: Size(width, 640),
            overrides: _baseOverrides(
              expenses: [worstCase, duplicate],
              categories: [category],
              // Checklist hidden: these assert expense-tile layout only.
              settings: const UserSettings(firstStepsDismissed: true),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(PendingBadge), findsWidgets);
          expect(find.byType(DuplicateWarningBadge), findsWidgets);
        },
      );
    }
  });

  group('HomeView long category subtitle regression', () {
    const longCategoryName =
        'Supermercado y almacén con un nombre extremadamente largo que no cabe';

    final category = makeCategory(name: longCategoryName);
    final date = DateTime(2025, 7, 10);
    final longExpense = makeExpense(
      amount: 1234567.89,
      description:
          'Compra muy larga en el supermercado con descripción extensa que debe truncarse',
      date: date,
      syncStatus: ExpenseSyncStatus.pending,
    );
    final duplicate = makeExpense(
      id: 2,
      amount: 1234567.89,
      description:
          'Compra muy larga en el supermercado con descripción extensa que debe truncarse',
      date: date,
      syncStatus: ExpenseSyncStatus.pending,
    );

    for (final width in [320.0, 360.0]) {
      testWidgets(
        'keeps long category on one line and date visible at ${width.toInt()}px',
        (tester) async {
          await _pumpHome(
            tester,
            size: Size(width, 640),
            overrides: _baseOverrides(
              expenses: [longExpense, duplicate],
              categories: [category],
              // Checklist hidden: these assert expense-tile layout only.
              settings: const UserSettings(firstStepsDismissed: true),
            ),
          );

          expect(tester.takeException(), isNull);

          final subtitle = '$longCategoryName · ${formatHumanDate(date)}';
          final subtitleTexts = tester.widgetList<Text>(find.text(subtitle));
          expect(subtitleTexts, isNotEmpty);
          for (final text in subtitleTexts) {
            expect(text.maxLines, 1);
            expect(text.overflow, TextOverflow.ellipsis);
          }

          expect(
            tester.getSize(find.byType(ListTile).first).height,
            lessThan(150),
          );
        },
      );
    }
  });

  group('HomeView first-steps checklist', () {
    testWidgets('visible when not dismissed and not all steps done', (
      tester,
    ) async {
      await _pumpHome(tester);

      expect(find.byType(FirstStepsChecklist), findsOneWidget);
      expect(find.text('Primeros pasos'), findsOneWidget);
      expect(find.text('Registrá tu primer gasto'), findsOneWidget);
      expect(find.text('Invitá a alguien a tu hogar'), findsOneWidget);
    });

    testWidgets('hidden when firstStepsDismissed is true', (tester) async {
      await _pumpHome(
        tester,
        overrides: _baseOverrides(
          settings: const UserSettings(firstStepsDismissed: true),
        ),
      );

      expect(find.byType(FirstStepsChecklist), findsNothing);
      expect(find.text('Primeros pasos'), findsNothing);
    });

    testWidgets('hidden when all steps are done', (tester) async {
      await _pumpHome(
        tester,
        overrides: _baseOverrides(
          expenses: [makeExpense(date: DateTime.now())],
          members: _twoMembers,
          settings: const UserSettings(monthProjectionEnabled: true),
        ),
      );

      expect(find.byType(FirstStepsChecklist), findsNothing);
      expect(find.text('Primeros pasos'), findsNothing);
    });
  });
}
