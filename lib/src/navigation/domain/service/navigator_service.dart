/// Contract for pure navigation operations.
///
/// Does NOT include `pop()` — dialogs and widgets use
/// `Navigator.of(context).pop()` directly.
abstract class NavigatorBase {
  void goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
    String? fragment,
  });
}
