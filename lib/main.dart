import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:biyuya/src/core/core.dart';
import 'package:biyuya/src/core/provider/theme_provider.dart';
import 'package:biyuya/src/navigation/provider/router_provider.dart';
import 'package:biyuya/src/navigation/routes/app_routes.dart';
import 'package:biyuya/theme/theme.dart';
import 'package:biyuya/theme/theme_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  EnvironmentConfig.validate();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _lastUri;
  DateTime? _lastUriAt;

  @override
  void initState() {
    super.initState();
    unawaited(_initDeepLinks());
    // Load persisted theme preference (default: light)
    unawaited(
      Future.microtask(() => ref.read(themeProvider.notifier).loadSaved()),
    );
  }

  @override
  void dispose() {
    unawaited(_linkSubscription?.cancel());
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle cold start deep link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } on Object catch (_) {
      // No initial link available
    }

    // Handle subsequent deep links (warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {},
    );
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'biyuya') {
      return;
    }
    if (uri.host != 'expense' || (uri.path != '/new' && uri.path != '/new/')) {
      return;
    }

    // Cold start can dispatch the same URI twice (getInitialLink + uriLinkStream).
    final now = DateTime.now();
    if (uri == _lastUri &&
        _lastUriAt != null &&
        now.difference(_lastUriAt!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastUri = uri;
    _lastUriAt = now;

    final categoryId = int.tryParse(uri.queryParameters['categoryId'] ?? '');
    final target = categoryId == null
        ? AppRoute.expenseNew.path
        : '${AppRoute.expenseNew.path}?categoryId=$categoryId';

    debugPrint('[DeepLink] handling $uri -> $target');

    // Delay navigation slightly to let auth redirect resolve first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Persist target so the redirect can re-issue it once auth resolves
      // (cold start: authSessionControllerProvider is still `loading`).
      ref.read(pendingDeepLinkProvider.notifier).target = target;
      ref.read(routerProvider).go(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    final textTheme = createTextTheme(context, 'Inter', 'Roboto');

    final theme = MaterialTheme(textTheme);

    return MaterialApp.router(
      title: 'Cuentas claras',
      debugShowCheckedModeBanner: false,
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode: themeMode.isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        ...GlobalCupertinoLocalizations.delegates,
        ...GlobalMaterialLocalizations.delegates,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      locale: const Locale('es', 'ES'),
    );
  }
}
