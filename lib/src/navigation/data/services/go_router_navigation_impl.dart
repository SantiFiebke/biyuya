import 'package:biyuya/src/navigation/domain/domain.dart';
import 'package:go_router/go_router.dart';

/// Concrete implementation of [NavigatorBase] that delegates
/// navigation to GoRouter.
class GoRouterNavigator implements NavigatorBase {
  const GoRouterNavigator(this._router);

  final GoRouter _router;

  @override
  void goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
    String? fragment,
  }) {
    _router.goNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
      fragment: fragment,
    );
  }
}