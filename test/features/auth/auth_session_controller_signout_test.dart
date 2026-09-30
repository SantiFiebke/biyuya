// Regression: cross-account data leak through `AuthSessionController`.
//
// `signOut()` and `deleteAccount()` both run `_resetSessionState()`, which
// must (1) invalidate the 7 session-scoped providers, (2) invalidate
// `pendingDeepLinkProvider`, (3) reset the theme to light + drop the
// `theme_mode` SharedPreferences key, and (4) clear the pending-expense
// outbox + the `cached_categories` CategoryCache. Every part has a dedicated
// assertion here; removing any single reset call makes this test fail.
//
// The auth-stream-null path (`_scheduleResetSessionState`, token expiry /
// remote sign-out) must run the SAME reset — covered by the group
// "auth stream null" below; it fails if the listener-triggered reset goes away.
//
// Design notes:
// - The auth stream is NOT emitted null after signOut, so the session keeps
//   household '1'. The only trigger that can rebuild the seven providers is
//   the explicit invalidate call. If the session went null,
//   householdMembers/householdName/expenseList would rebuild from their
//   session dependency alone and mask a missing invalidate.
// - Invalidation is asserted with rebuild-counting `container.listen`
//   callbacks: after signOut the controllers reload from the still-seeded
//   fakes, so final data looks the same before and after — only a rebuild
//   counter proves the invalidate ran. For the auth-stream-null path the
//   four NON-session-dependent controllers (category/expense/report/settings)
//   are the ones that prove the invalidate ran.
// - `householdNameProvider.build()` queries Supabase directly (no repository
//   seam), so its value is null in tests no matter what we seed. Its
//   invalidation is asserted via the rebuild counter only.
// - Settings seed uses `debtSettlementEnabled: true` so the post-invalidate
//   default state differs and the listener is guaranteed to fire.
import 'dart:async';

import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:biyuya/src/core/network/connectivity_provider.dart';
import 'package:biyuya/src/core/network/supabase_client_provider.dart';
import 'package:biyuya/src/core/provider/theme_provider.dart';
import 'package:biyuya/src/features/auth/domain/repositories/auth_repository_base.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/auth/provider/auth_repository_provider.dart';
import 'package:biyuya/src/features/auth/provider/household_members_provider.dart';
import 'package:biyuya/src/features/auth/provider/household_provider.dart';
import 'package:biyuya/src/features/categories/data/local/category_cache.dart';
import 'package:biyuya/src/features/categories/data/repositories/category_repository_impl.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/presentation/controllers/category_controller.dart';
import 'package:biyuya/src/features/categories/provider/category_repository_provider.dart';
import 'package:biyuya/src/features/expenses/data/local/pending_expense_store.dart';
import 'package:biyuya/src/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';
import 'package:biyuya/src/features/expenses/domain/repositories/expense_repository_base.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:biyuya/src/features/expenses/presentation/controllers/expense_list_controller.dart';
import 'package:biyuya/src/features/expenses/provider/expense_repository_provider.dart';
import 'package:biyuya/src/features/reports/data/repositories/report_repository_impl.dart';
import 'package:biyuya/src/features/reports/domain/entities/monthly_report.dart';
import 'package:biyuya/src/features/reports/presentation/controllers/report_controller.dart';
import 'package:biyuya/src/features/reports/provider/report_repository_provider.dart';
import 'package:biyuya/src/features/settings/domain/entities/user_settings.dart';
import 'package:biyuya/src/features/settings/domain/repositories/settings_repository_base.dart';
import 'package:biyuya/src/features/settings/presentation/controllers/settings_controller.dart';
import 'package:biyuya/src/features/settings/provider/settings_repository_provider.dart';
import 'package:biyuya/src/navigation/provider/router_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAuthRepository extends Mock implements AuthRepositoryBase {}

class MockExpenseRepository extends Mock implements ExpenseRepositoryImpl {}

class MockCategoryRepository extends Mock implements CategoryRepositoryImpl {}

class MockReportRepository extends Mock implements ReportRepositoryImpl {}

class MockSettingsRepository extends Mock implements SettingsRepositoryBase {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

// ---------------------------------------------------------------------------
// Seed data (account-1)
// ---------------------------------------------------------------------------

const signedInUser = UserProfile(
  id: 'user-1',
  name: 'Test',
  lastName: 'User',
  householdId: '1',
);

const householdMember = UserProfile(
  id: 'member-1',
  name: 'Ana',
  lastName: 'Gómez',
  householdId: '1',
);

final seededCategory = Category(
  id: 1,
  name: 'Comida',
  householdId: 1,
  createdAt: DateTime(2025),
);

final seededExpense = Expense(
  id: 1,
  amount: 1500,
  date: DateTime(2025, 7, 15),
  description: 'Synced expense',
  householdId: 1,
  categoryId: 1,
  createdAt: DateTime(2025, 7, 15),
);

final pendingExpense = Expense.pending(
  amount: 300,
  date: DateTime(2025, 7, 16),
  householdId: 1,
  categoryId: 1,
  clientId: 'client-1',
  description: 'Pending offline',
);

const seededReport = MonthlyReport(
  total: 1500,
  previousTotal: 1000,
  variation: 50,
  categoryBreakdowns: [],
  year: 2025,
  month: 7,
);

// Non-default flag so the post-invalidate default state differs and the
// settings listener is guaranteed to fire.
const seededSettings = UserSettings(debtSettlementEnabled: true);

const resetTargetKeys = [
  'categoryController',
  'expenseController',
  'expenseListController',
  'reportController',
  'householdName',
  'householdMembers',
  'settingsController',
];

// ExpenseController is excluded from the listener block on purpose: with an
// active listener its post-reset rebuild runs _emitExpenses → syncTotal and
// rewrites the widget prefs we assert are cleared. Its invalidation is
// instead proven by the lazy-rebuild + Error-state check in
// expectFullSessionReset.
const listenerKeys = [
  'categoryController',
  'expenseListController',
  'reportController',
  'householdName',
  'householdMembers',
  'settingsController',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late MockAuthRepository authRepo;
  late StreamController<UserProfile?> authStateController;
  late StreamController<UserProfile?> profileController;
  late Map<String, int> rebuilds;

  setUp(() async {
    // ThemeMode.values = [system, light, dark] → index 2 = dark, so the
    // before/after theme assertions actually differ. Widget prefs seed the
    // keys that `_resetSessionState`'s clearTotal must wipe on BOTH the
    // explicit and the implicit (auth-stream null) paths (TEST-003).
    SharedPreferences.setMockInitialValues({
      'theme_mode': 2,
      'widget_daily_total': '999.0',
      'widget_daily_date': '2026-01-01',
      'widget_featured_categories': '[{"id":1,"name":"Comida"}]',
    });
    await const PendingExpenseStore().save([pendingExpense]);
    // CategoryCache must also be wiped by the reset — seed it here.
    await const CategoryCache().save([seededCategory]);

    authStateController = StreamController<UserProfile?>();
    profileController = StreamController<UserProfile?>();

    authRepo = MockAuthRepository();
    when(
      () => authRepo.onAuthStateChanged,
    ).thenAnswer((_) => authStateController.stream);
    when(
      () => authRepo.onProfileChanged(userId: any(named: 'userId')),
    ).thenAnswer((_) => profileController.stream);
    when(() => authRepo.signOut()).thenAnswer((_) async => const Success(null));
    when(
      () => authRepo.deleteAccount(),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => authRepo.getHouseholdMembers(householdId: 1),
    ).thenAnswer((_) async => const Success([householdMember]));

    final expenseRepo = MockExpenseRepository();
    // First load feeds expectSeededAccount1Data; any reload AFTER the reset
    // errors (stale-data guard), so the post-invalidate rebuild is observable
    // without a successful _emitExpenses rewriting the widget prefs.
    var monthLoads = 0;
    when(
      () => expenseRepo.getExpensesByMonth(
        householdId: 1,
        year: any(named: 'year'),
        month: any(named: 'month'),
      ),
    ).thenAnswer((_) async {
      monthLoads += 1;
      if (monthLoads == 1) {
        return Success([seededExpense]);
      }
      return const Error(ExpenseFailure('stale reload after reset'));
    });
    when(
      () => expenseRepo.getExpensesPage(
        householdId: 1,
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => Success([seededExpense]));

    final categoryRepo = MockCategoryRepository();
    when(
      () => categoryRepo.getCategories(householdId: 1),
    ).thenAnswer((_) async => Success([seededCategory]));

    final reportRepo = MockReportRepository();
    when(
      () => reportRepo.getMonthlyReport(
        householdId: 1,
        year: any(named: 'year'),
        month: any(named: 'month'),
        categories: any(named: 'categories'),
      ),
    ).thenAnswer((_) async => const Success(seededReport));

    final settingsRepo = MockSettingsRepository();
    when(
      settingsRepo.getSettings,
    ).thenAnswer((_) async => const Success(seededSettings));

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        expenseRepositoryProvider.overrideWithValue(expenseRepo),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        reportRepositoryProvider.overrideWithValue(reportRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        // householdNameProvider.build() hits Supabase directly; the mock
        // throws MissingStubError inside its `on Object` catch → null.
        supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
        // Offline: keeps expenseController from flushing the outbox on boot,
        // which would clear the pending key before the test seeds its asserts.
        isOnlineProvider.overrideWith((ref) => Stream<bool>.value(false)),
      ],
    );
    addTearDown(container.dispose);

    // Signed-in session with household '1' — never emitted null afterwards.
    container.listen(authSessionControllerProvider, (_, _) {});
    authStateController.add(signedInUser);
    await pumpEventQueue();

    // Trigger the initial load of every reset target.
    container
      ..read(categoryControllerProvider)
      ..read(expenseControllerProvider)
      ..read(expenseListControllerProvider)
      ..read(reportControllerProvider)
      ..read(settingsControllerProvider)
      ..read(householdMembersProvider)
      ..read(householdNameProvider);
    await pumpEventQueue();

    await container.read(themeProvider.notifier).loadSaved();

    // Pending deep link must be invalidated by the reset too. Reading it
    // first keeps the keepAlive element alive so a missing invalidate leaves
    // the stale target in place (and the assertion below fails).
    container.read(pendingDeepLinkProvider.notifier).target = '/expenses/new';

    rebuilds = {};
    void count(String key) => rebuilds[key] = (rebuilds[key] ?? 0) + 1;
    container
      ..listen(
        categoryControllerProvider,
        (_, _) => count('categoryController'),
      )
      ..listen(
        expenseListControllerProvider,
        (_, _) => count('expenseListController'),
      )
      ..listen(reportControllerProvider, (_, _) => count('reportController'))
      ..listen(householdNameProvider, (_, _) => count('householdName'))
      ..listen(householdMembersProvider, (_, _) => count('householdMembers'))
      ..listen(
        settingsControllerProvider,
        (_, _) => count('settingsController'),
      );
    await pumpEventQueue();
  });

  tearDown(() {
    unawaited(authStateController.close());
    unawaited(profileController.close());
  });

  Future<void> expectSeededAccount1Data() async {
    expect(
      container.read(categoryControllerProvider).value?.single.name,
      'Comida',
    );
    // Synced expense + pending outbox entry.
    expect(container.read(expenseControllerProvider).value, hasLength(2));
    expect(container.read(expenseListControllerProvider).items, hasLength(2));
    expect(container.read(reportControllerProvider).value?.report?.total, 1500);
    expect(
      container.read(settingsControllerProvider).value?.debtSettlementEnabled,
      isTrue,
    );
    expect(container.read(householdMembersProvider).value, hasLength(1));

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getInt('theme_mode'),
      2,
      reason: 'seeded theme_mode prefs value missing',
    );
    expect(
      container.read(themeProvider),
      ThemeMode.dark,
      reason:
          'theme not dark before signOut (values: ${ThemeMode.values}, '
          'state: ${container.read(themeProvider)})',
    );
    expect(await const PendingExpenseStore().load(), hasLength(1));
    expect(
      prefs.getString('cached_categories'),
      isNotNull,
      reason: 'seeded CategoryCache entry missing',
    );
    expect(
      container.read(pendingDeepLinkProvider),
      '/expenses/new',
      reason: 'seeded pending deep link missing',
    );
    // Widget prefs present before the reset (seeded, or rewritten by the
    // expense controller's initial sync — both non-null).
    expect(
      prefs.getString('widget_daily_total'),
      isNotNull,
      reason: 'seeded widget_daily_total missing',
    );
    expect(
      prefs.getString('widget_featured_categories'),
      isNotNull,
      reason: 'seeded widget_featured_categories missing',
    );
  }

  Future<void> expectFullSessionReset(
    String action, {
    bool verifyExpenseController = true,
  }) async {
    for (final key in listenerKeys) {
      expect(
        rebuilds[key],
        greaterThan(0),
        reason:
            '$key was not invalidated by $action — stale account-1 data '
            'would leak into the next session.',
      );
    }
    if (verifyExpenseController) {
      // No active listener → invalidate is lazy: the next read rebuilds, and
      // the 2nd getExpensesByMonth call errors (stale-data guard above), so
      // hasError proves the rebuild ran WITHOUT a successful _emitExpenses
      // rewriting the widget prefs asserted cleared below.
      container.read(expenseControllerProvider);
      await pumpEventQueue();
      expect(
        container.read(expenseControllerProvider).hasError,
        isTrue,
        reason:
            'expenseController was not invalidated by $action — stale '
            'account-1 expenses would leak into the next session.',
      );
    }
    expect(
      container.read(themeProvider),
      ThemeMode.light,
      reason: 'theme not reset to light by $action',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getInt('theme_mode'),
      isNull,
      reason: 'theme_mode prefs key not removed by $action',
    );
    expect(
      prefs.getString('pending_expenses'),
      isNull,
      reason: 'pending outbox key not removed by $action',
    );
    expect(await const PendingExpenseStore().load(), isEmpty);
    expect(
      prefs.getString('cached_categories'),
      isNull,
      reason:
          'CategoryCache not cleared by $action — stale categories '
          'would leak into the next account.',
    );
    expect(
      container.read(pendingDeepLinkProvider),
      isNull,
      reason:
          'pending deep link not invalidated by $action — a stale '
          'target would hijack navigation for the next account.',
    );
    // Widget prefs cleared by clearTotal inside _resetSessionState — covers
    // the implicit auth-stream-null path too, not only explicit signOut.
    expect(
      prefs.getString('widget_daily_total'),
      isNull,
      reason: 'widget_daily_total not cleared by $action',
    );
    expect(
      prefs.getString('widget_daily_date'),
      isNull,
      reason: 'widget_daily_date not cleared by $action',
    );
    expect(
      prefs.getString('widget_featured_categories'),
      isNull,
      reason: 'widget_featured_categories not cleared by $action',
    );
  }

  group('AuthSessionController._resetSessionState', () {
    test(
      'signOut invalidates session providers, resets theme, clears outbox',
      () async {
        await expectSeededAccount1Data();
        rebuilds.clear();

        await container.read(authSessionControllerProvider.notifier).signOut();
        await pumpEventQueue();

        await expectFullSessionReset('signOut');
      },
    );

    test('deleteAccount invalidates session providers, resets theme, '
        'clears outbox', () async {
      await expectSeededAccount1Data();
      rebuilds.clear();

      final result = await container
          .read(authSessionControllerProvider.notifier)
          .deleteAccount();
      expect(result.isSuccess(), isTrue);
      await pumpEventQueue();

      await expectFullSessionReset('deleteAccount');
    });
  });

  group('auth stream null (token expiry / remote sign-out)', () {
    test(
      'session -> null runs the same reset without explicit signOut',
      () async {
        await expectSeededAccount1Data();
        rebuilds.clear();

        // No signOut() call: only the auth stream drops the session.
        authStateController.add(null);
        await pumpEventQueue();

        expect(
          container.read(authSessionControllerProvider).value,
          isNull,
          reason: 'session should be null after auth stream emitted null',
        );

        // expenseController would rewrite widget prefs with _emitExpenses([])
        // on its post-reset rebuild (household null short-circuit), so its
        // invalidation is covered by the signOut/deleteAccount proofs above.
        await expectFullSessionReset(
          'auth stream null',
          verifyExpenseController: false,
        );
      },
    );
  });

  group('cold start (TEST-003): first auth emission is null', () {
    test('reset runs with no prior user (token expiry cold start)', () async {
      // Fresh container: setUp's container already saw signedInUser, which
      // would make _lastUserId non-null and mask the `userProfile == null`
      // guard this test exists to cover.
      final coldAuth = StreamController<UserProfile?>();
      final coldProfile = StreamController<UserProfile?>();
      // Non-awaiting closures: coldProfile is never listened (first
      // emission is null → no profile subscription), and awaiting its
      // done future would hang the teardown until the 30s test timeout.
      addTearDown(() {
        unawaited(coldAuth.close());
        unawaited(coldProfile.close());
      });

      final coldRepo = MockAuthRepository();
      when(
        () => coldRepo.onAuthStateChanged,
      ).thenAnswer((_) => coldAuth.stream);
      when(
        () => coldRepo.onProfileChanged(userId: any(named: 'userId')),
      ).thenAnswer((_) => coldProfile.stream);

      // settingsController._load always hits the repository (no session
      // check); every other target early-returns on a null household.
      final coldSettingsRepo = MockSettingsRepository();
      when(
        coldSettingsRepo.getSettings,
      ).thenAnswer((_) async => const Success(seededSettings));

      final cold = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(coldRepo),
          settingsRepositoryProvider.overrideWithValue(coldSettingsRepo),
          supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
          isOnlineProvider.overrideWith((ref) => Stream<bool>.value(false)),
        ],
      );
      addTearDown(cold.dispose);

      // Build every reset target so the invalidation is observable.
      cold
        ..read(categoryControllerProvider)
        ..read(expenseControllerProvider)
        ..read(expenseListControllerProvider)
        ..read(reportControllerProvider)
        ..read(settingsControllerProvider)
        ..read(householdMembersProvider)
        ..read(householdNameProvider);
      await pumpEventQueue();
      await cold.read(themeProvider.notifier).loadSaved();

      final prefs = await SharedPreferences.getInstance();
      expect(
        cold.read(themeProvider),
        ThemeMode.dark,
        reason: 'cold container should start from the seeded dark theme',
      );
      expect(prefs.getInt('theme_mode'), 2, reason: 'theme seed missing');
      expect(
        prefs.getString('pending_expenses'),
        isNotNull,
        reason: 'pending outbox seed missing',
      );
      expect(
        prefs.getString('cached_categories'),
        isNotNull,
        reason: 'CategoryCache seed missing',
      );

      final coldRebuilds = <String, int>{};
      void count(String key) =>
          coldRebuilds[key] = (coldRebuilds[key] ?? 0) + 1;
      cold
        ..listen(
          categoryControllerProvider,
          (_, _) => count('categoryController'),
        )
        ..listen(
          expenseControllerProvider,
          (_, _) => count('expenseController'),
        )
        ..listen(
          expenseListControllerProvider,
          (_, _) => count('expenseListController'),
        )
        ..listen(reportControllerProvider, (_, _) => count('reportController'))
        ..listen(householdNameProvider, (_, _) => count('householdName'))
        ..listen(householdMembersProvider, (_, _) => count('householdMembers'))
        ..listen(
          settingsControllerProvider,
          (_, _) => count('settingsController'),
        );
      await pumpEventQueue();

      // Cold start after token expiry: FIRST emission, never signed in.
      coldAuth.add(null);
      await pumpEventQueue();

      final coldSession = cold.read(authSessionControllerProvider);
      expect(
        coldSession.isLoading,
        isFalse,
        reason: 'cold auth emission (null) never reached the listener',
      );
      expect(
        coldSession.value,
        isNull,
        reason: 'cold-start session should resolve to null',
      );
      // category/expense/expenseList/report rebuild to an IDENTICAL default
      // state in this cold scenario (never signed in → nothing seeded), and
      // Riverpod suppresses the notify, so no listener fires. Their
      // invalidation is proven by the signOut/deleteAccount tests, where
      // seeded data makes every rebuild observably change state.
      // householdName/householdMembers also rebuild from the session change
      // itself (mask, see TEST-001 header), so they can only corroborate.
      // settingsController has NO session dependency and only ever rebuilds
      // when invalidated — it is this test's invalidation tripwire.
      for (final key in const [
        'settingsController',
        'householdName',
        'householdMembers',
      ]) {
        expect(
          coldRebuilds[key],
          greaterThan(0),
          reason:
              '$key was not invalidated on cold-start null — previous '
              "account's data would leak into the next session "
              '(rebuilds: $coldRebuilds, theme: '
              '${cold.read(themeProvider)})',
        );
      }
      expect(
        cold.read(themeProvider),
        ThemeMode.light,
        reason: 'theme not reset to light on cold-start null',
      );
      expect(
        prefs.getInt('theme_mode'),
        isNull,
        reason: 'theme_mode prefs key not removed on cold-start null',
      );
      expect(
        prefs.getString('pending_expenses'),
        isNull,
        reason: 'pending outbox not cleared on cold-start null',
      );
      expect(
        prefs.getString('cached_categories'),
        isNull,
        reason: 'CategoryCache not cleared on cold-start null',
      );
    });
  });
}
