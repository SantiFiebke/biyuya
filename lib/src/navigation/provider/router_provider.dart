import 'package:biyuya/src/core/presentation/pages/splash_page.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_provider.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final authSessionAsync = ref.watch(authSessionControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const SizedBox(), // TODO
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const SizedBox(), // TODO
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const SizedBox(), // TODO
      ),
    ],
    redirect: (context, state) {
      return authSessionAsync.when(
        data: (userProfile) {
          FlutterNativeSplash.remove();

          final isLoggingIn = state.matchedLocation == '/login';

          if (userProfile == null) {
            return isLoggingIn ? null : '/login';
          }

          if (!userProfile.hasHousehold) {
            return '/onboarding';
          }

          if (isLoggingIn ||
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
          return '/splash';
        },
      );
    },
  );
}
