import 'package:biyuya/src/core/presentation/pages/splash_page.dart';
import 'package:biyuya/src/features/auth/presentation/presentation.dart';
import 'package:biyuya/src/features/categories/categories.dart';
import 'package:biyuya/src/features/expenses/expenses.dart';
import 'package:biyuya/src/features/home/home.dart';
import 'package:biyuya/src/features/profile/profile.dart';
import 'package:biyuya/src/features/reports/reports.dart';
import 'package:biyuya/src/navigation/presentation/main_shell.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_provider.g.dart';

/// Deep link objetivo guardado hasta que la sesión resuelva (cold start).
///
/// [AuthSessionController] arranca en `loading`; si navegáramos en ese momento
/// el redirect manda a splash y el target se pierde. El redirect consume este
/// valor una vez que hay usuario + household.
@Riverpod(keepAlive: true)
class PendingDeepLink extends _$PendingDeepLink {
  @override
  String? build() => null;

  String? get target => state;

  set target(String? value) => state = value;

  /// Devuelve el target pendiente y lo limpia (una sola vez).
  String? consume() {
    final target = state;
    state = null;
    return target;
  }
}

/// Notifier que retransmite los cambios del AuthSessionController a GoRouter
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authSessionControllerProvider, (_, _) => notifyListeners());
  }
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoute.splash.path,
    refreshListenable: refreshNotifier,
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('No se pudo abrir el enlace'))),
    routes: [
      // ── Top-level routes (fuera del shell) ──
      GoRoute(
        path: AppRoute.splash.path,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoute.login.path,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppRoute.register.path,
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: AppRoute.onboarding.path,
        builder: (context, state) => const OnboardingView(),
      ),
      GoRoute(
        path: AppRoute.categories.path,
        builder: (context, state) => const CategoryListView(),
      ),
      GoRoute(
        path: AppRoute.categoryNew.path,
        builder: (context, state) => const CategoryFormView(),
      ),
      GoRoute(
        path: '${AppRoute.categories.path}/:id/edit',
        builder: (context, state) {
          final category = state.extra as Category?;
          return CategoryFormView(category: category);
        },
      ),

      // ── Shell route con bottom navbar ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.home.path,
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),

          // Branch 1: Expenses (subrutas relativas)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.expenses.path,
                builder: (context, state) => const ExpenseListView(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => ExpenseFormView(
                      initialCategoryId: int.tryParse(
                        state.uri.queryParameters['categoryId'] ?? '',
                      ),
                    ),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) {
                      final expense = state.extra as Expense?;
                      return ExpenseFormView(expense: expense);
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final expense = state.extra as Expense?;
                      if (expense == null) {
                        return const Scaffold(
                          body: Center(child: Text('Gasto no encontrado')),
                        );
                      }
                      return ExpenseDetailView(expense: expense);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.reports.path,
                builder: (context, state) => const ReportView(),
              ),
            ],
          ),

          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.profile.path,
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final authSessionAsync = ref.read(authSessionControllerProvider);

      return authSessionAsync.when(
        data: (userProfile) {
          final loc = state.matchedLocation;
          final isLoggingIn = loc == AppRoute.login.path;
          final isRegistering = loc == AppRoute.register.path;
          // ponytail: techo — verificar email deshabilitado; reactivar este
          // guard junto con "Confirm email" en Supabase (y la ruta
          // verifyEmail en app_routes.dart).
          // final isVerifyingEmail = loc == AppRoute.verifyEmail.path;

          // 1. Without session
          if (userProfile == null) {
            FlutterNativeSplash.remove();
            return (isLoggingIn || isRegistering /* || isVerifyingEmail */ )
                ? null
                : AppRoute.login.path;
          }

          // Auth resolved with valid user — remove native splash
          FlutterNativeSplash.remove();

          // 2. With valid session but no household
          if (!userProfile.hasHousehold) {
            return loc == AppRoute.onboarding.path
                ? null
                : AppRoute.onboarding.path;
          }

          // 3. Consume pending deep link (survives login/onboarding). Returning
          // the current location when pending == loc is a no-op for GoRouter.
          final pending = ref.read(pendingDeepLinkProvider.notifier).consume();
          if (pending != null) {
            return pending;
          }

          // 4. With valid session and household
          if (isLoggingIn ||
              isRegistering ||
              // isVerifyingEmail ||  // ver nota del guard de arriba
              loc == AppRoute.splash.path ||
              loc == AppRoute.onboarding.path) {
            return AppRoute.home.path;
          }

          return null;
        },
        error: (_, _) {
          FlutterNativeSplash.remove();
          return AppRoute.login.path;
        },
        loading: () {
          return AppRoute.splash.path;
        },
      );
    },
  );
}
