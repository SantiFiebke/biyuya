import 'package:biyuya/src/navigation/presentation/main_shell.dart';
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
    testWidgets('shows the 4 tab destinations', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Gastos'), findsOneWidget);
      expect(find.text('Reportes'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('switches to another tab', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gastos'));
      await tester.pumpAndSettle();

      expect(find.text('EXPENSES'), findsOneWidget);
    });
  });
}
