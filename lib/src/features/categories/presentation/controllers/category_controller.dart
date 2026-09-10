import 'dart:async';

import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/provider/category_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_controller.g.dart';

@Riverpod(keepAlive: true)
class CategoryController extends _$CategoryController {
  @override
  AsyncValue<List<Category>> build() {
    unawaited(Future.microtask(_loadCategories));
    return const AsyncData([]);
  }

  Future<void> _loadCategories() async {
    final session = ref.read(authSessionControllerProvider);
    final householdId = session.value?.householdId;

    if (householdId == null || householdId.isEmpty) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();
    final repository = ref.read(categoryRepositoryProvider);
    final result = await repository.getCategories(
      householdId: int.parse(householdId),
    );
    result.when(
      (categories) => state = AsyncData(categories),
      (failure) => state = AsyncError(failure, StackTrace.current),
    );
  }

  Future<bool> createCategory({
    required String name,
    String? color,
    String? icon,
  }) async {
    final session = ref.read(authSessionControllerProvider);
    final householdId = session.value?.householdId;

    if (householdId == null || householdId.isEmpty) {
      return false;
    }

    final repository = ref.read(categoryRepositoryProvider);
    final result = await repository.createCategory(
      name: name,
      color: color,
      icon: icon,
      householdId: int.parse(householdId),
    );
    // ignore: async_return_with_no_await — result.when returns directly; async needed for repository await above
    return result.when(
      (category) {
        state = AsyncData([...state.value ?? [], category]);
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> updateCategory({
    required int id,
    required String name,
    String? color,
    String? icon,
  }) async {
    final repository = ref.read(categoryRepositoryProvider);
    final result = await repository.updateCategory(
      id: id,
      name: name,
      color: color,
      icon: icon,
    );
    // ignore: async_return_with_no_await — result.when returns directly; async needed for repository await above
    return result.when(
      (updated) {
        final categories = state.value ?? [];
        final index = categories.indexWhere((c) => c.id == id);
        if (index != -1) {
          categories[index] = updated;
          state = AsyncData(List.from(categories));
        }
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> deleteCategory({required int id}) async {
    final repository = ref.read(categoryRepositoryProvider);
    final result = await repository.deleteCategory(id: id    );
    // ignore: async_return_with_no_await — result.when returns directly; async needed for repository await above
    return result.when(
      (_) {
        final categories = state.value ?? [];
        state = AsyncData(categories.where((c) => c.id != id).toList());
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }
}
