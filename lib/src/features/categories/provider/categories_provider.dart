import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/provider/category_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'categories_provider.g.dart';

/// Sin retry: un fallo del fetch debe propagarse ya, no reintentar en bucle
/// (el default de Riverpod reintenta 10 veces con backoff exponencial).
Duration? _noRetry(int retryCount, Object error) => null;

/// Única fuente de categorías del hogar. La comparten el reporte y el
/// CategoryController: así `getCategories` no se llama dos veces.
@Riverpod(keepAlive: true, retry: _noRetry)
Future<List<Category>> categories(Ref ref) async {
  final householdId = ref
      .watch(authSessionControllerProvider)
      .value
      ?.householdIdValue;
  if (householdId == null) {
    return const <Category>[];
  }
  final result = await ref
      .watch(categoryRepositoryProvider)
      .getCategories(householdId: householdId);
  return result.when<List<Category>>(
    (categories) => categories,
    (failure) => throw Exception(failure.message),
  );
}
