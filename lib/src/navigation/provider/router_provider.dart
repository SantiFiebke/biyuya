import 'package:biyuya/src/core/presentation/pages/splash_page.dart';
import 'package:biyuya/src/features/auth/presentation/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_provider.g.dart';

/// Notifier que retransmite los cambios del AuthSessionController a GoRouter
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(
      authSessionControllerProvider,
      (_, __) => notifyListeners(),
    );
  }
}

@riverpod
GoRouter router(Ref ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const SizedBox(), // TODO: OnboardingView
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const SizedBox(), // TODO: HomeView
      ),
    ],
    redirect: (context, state) {
      final authSessionAsync = ref.read(authSessionControllerProvider);

      return authSessionAsync.when(
        data: (userProfile) {
          FlutterNativeSplash.remove();

          final isLoggingIn = state.matchedLocation == '/login';
          final isRegistering = state.matchedLocation == '/register';
          final isVerifyingEmail = state.matchedLocation == '/verify-email';

          // 1. Sin sesión
          if (userProfile == null) {
            return (isLoggingIn || isRegistering || isVerifyingEmail)
                ? null
                : '/login';
          }

          // 2. Con sesión activa pero sin hogar
          if (!userProfile.hasHousehold) {
            return state.matchedLocation == '/onboarding'
                ? null
                : '/onboarding';
          }

          // 3. Con sesión y con hogar
          if (isLoggingIn ||
              isRegistering ||
              isVerifyingEmail ||
              state.matchedLocation == '/splash' ||
              state.matchedLocation == '/onboarding') {
            return '/home';
          }

          return null;
        },
        error: (_, _) {
          FlutterNativeSplash.remove();
          return '/login';
        },
        loading: () {
          // Mantiene /splash (mientras el Splash Nativo aún sigue visible cubriéndolo)
          return '/splash';
        },
      );
    },
  );
}
