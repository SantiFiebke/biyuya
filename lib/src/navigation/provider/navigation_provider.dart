import 'package:biyuya/src/navigation/data/services/go_router_navigation_impl.dart';
import 'package:biyuya/src/navigation/domain/service/navigator_service.dart';
import 'package:biyuya/src/navigation/provider/router_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Provides the [NavigatorBase] implementation.
///
/// Delegates to GoRouter via [GoRouterNavigator].
@Riverpod(keepAlive: true)
NavigatorBase navigator(Ref ref) {
  final router = ref.read(routerProvider);
  return GoRouterNavigator(router);
}
