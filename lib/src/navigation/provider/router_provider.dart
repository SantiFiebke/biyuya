import 'package:biyuya/src/core/presentation/pages/splash_page.dart';
import 'package:biyuya/src/features/auth/presentation/presentation.dart';
import 'package:biyuya/src/features/categories/categories.dart';
import 'package:biyuya/src/features/expenses/expenses.dart';
import 'package:biyuya/src/features/home/home.dart';
import 'package:biyuya/src/features/profile/profile.dart';
import 'package:biyuya/src/features/reports/reports.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_provider.g.dart';

/// Notifier que retransmite los cambios del AuthSessionController a GoRouter
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authSessionControllerProvider, (_, _) => notifyListeners());
  }
}

@riverpod
GoRouter router(Ref ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoute.splash.path,
    refreshListenable: refreshNotifier,
    routes: [
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
        path: AppRoute.home.path,
        builder: (context, state) => const HomeView(),
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
      GoRoute(
        path: AppRoute.expenses.path,
        builder: (context, state) => const ExpenseListView(),
      ),
      GoRoute(
        path: AppRoute.expenseNew.path,
        builder: (context, state) {
          return const ExpenseFormView();
        },
      ),
      GoRoute(
        path: '${AppRoute.expenses.path}/:id/edit',
        builder: (context, state) {
          final expense = state.extra as Expense?;
          return ExpenseFormView(expense: expense);
        },
      ),
      GoRoute(
        path: '${AppRoute.expenses.path}/:id',
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
      GoRoute(
        path: AppRoute.reports.path,
        builder: (context, state) => const ReportView(),
      ),
      GoRoute(
        path: AppRoute.profile.path,
        builder: (context, state) => const ProfileView(),
      ),
    ],
    redirect: (context, state) {
      final authSessionAsync = ref.read(authSessionControllerProvider);

      return authSessionAsync.when(
        data: (userProfile) {
          final loc = state.matchedLocation;
          final isLoggingIn = loc == AppRoute.login.path;
          final isRegistering = loc == AppRoute.register.path;
          final isVerifyingEmail = loc == AppRoute.verifyEmail.path;

          // 1. Sin sesión
          if (userProfile == null) {
            FlutterNativeSplash.remove();
            return (isLoggingIn || isRegistering || isVerifyingEmail)
                ? null
                : AppRoute.login.path;
          }

          // Auth resolved with valid user — remove native splash
          FlutterNativeSplash.remove();

          // 2. Con sesión activa pero sin hogar
          if (!userProfile.hasHousehold) {
            return loc == AppRoute.onboarding.path
                ? null
                : AppRoute.onboarding.path;
          }

          // 3. Con sesión y con hogar
          if (isLoggingIn ||
              isRegistering ||
              isVerifyingEmail ||
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
          // Mantiene /splash (mientras el Splash Nativo aún sigue visible cubriéndolo)
          return AppRoute.splash.path;
        },
      );
    },
  );
}
