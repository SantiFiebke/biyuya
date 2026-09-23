import 'package:biyuya/src/core/network/connectivity_provider.dart';
import 'package:biyuya/src/core/presentation/widgets/offline_banner.dart';
import 'package:biyuya/src/navigation/presentation/main_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const Scaffold(body: Text('HOME')),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/expenses',
              builder: (_, _) => const Scaffold(body: Text('EXPENSES')),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (_, _) => const Scaffold(body: Text('REPORTS')),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const Scaffold(body: Text('PROFILE')),
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  group('MainShell', () {
    Future<void> pumpShell(WidgetTester tester, {bool isOnline = true}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => Stream.value(isOnline)),
          ],
          child: MaterialApp.router(routerConfig: _buildRouter()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the 4 tab destinations', (tester) async {
      await pumpShell(tester);

      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Gastos'), findsOneWidget);
      expect(find.text('Reportes'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('switches to another tab', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Gastos'));
      await tester.pumpAndSettle();

      expect(find.text('EXPENSES'), findsOneWidget);
    });

    testWidgets('shows OfflineBanner when offline', (tester) async {
      await pumpShell(tester, isOnline: false);

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.textContaining('Sin conexión'), findsOneWidget);
    });

    testWidgets('hides OfflineBanner when online', (tester) async {
      await pumpShell(tester);

      expect(find.textContaining('Sin conexión'), findsNothing);
    });
  });
}
