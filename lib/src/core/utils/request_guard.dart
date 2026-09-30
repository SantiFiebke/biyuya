/// Guard de respuestas asíncronas obsoletas.
///
/// Dart no cancela un `Future` ya lanzado. Este mixin declara un contador
/// `_epoch`: cada carga "marca" su inicio y, al volver de red, descarta
/// su resultado si ya no es la última.
///
/// Uso de alto nivel — una sola request:
/// ```dart
/// final result = await runLatest(() => repo.fetch());
/// if (result == null) return; // obsoleta: arrancó otra carga
/// ```
///
/// Uso de bajo nivel — varias awaits en la misma carga, o requests que NO deben
/// iniciar una nueva (p. ej. paginación):
/// ```dart
/// final token = startRequest();
/// ...
/// if (isStale(token)) return;
/// ```
mixin RequestGuard {
  int _epoch = 0;

  /// Inicia una carga nueva e invalida las anteriores. Devuelve su token.
  int startRequest() => ++_epoch;

  /// Token de la carga vigente, SIN iniciar una (para operaciones que
  /// comparten el ciclo actual, como `loadMore`).
  int get currentRequest => _epoch;

  /// `true` si [token] quedó obsoleto (arrancó otra carga después).
  bool isStale(int token) => token != _epoch;

  /// Invalida cualquier carga en vuelo sin iniciar una — usar en `build()`
  /// para resetear tras un rebuild.
  void invalidateRequests() => _epoch++;

  /// Ejecuta [request] como la carga vigente y devuelve su resultado, o `null`
  /// si mientras tanto arrancó otra carga.
  Future<R?> runLatest<R>(Future<R> Function() request) async {
    final token = startRequest();
    final result = await request();
    return isStale(token) ? null : result;
  }
}
