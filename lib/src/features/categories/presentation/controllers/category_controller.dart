// ignore_for_file: async_return_with_no_await — result.when returns directly; async needed for repository await above

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
    result.when((categories) {
      state = AsyncData(categories);
    }, (failure) => state = AsyncError(failure, StackTrace.current));
  }

  Future<bool> createCategory({
    required String name,
    String? color,
    String? icon,
    double? budgetAmount,
  }) async {
    final session = ref.read(authSessionControllerProvider);
    final householdId = session.value?.householdId;

    if (householdId == null || householdId.isEmpty) {
      return false;
    }

    final previous = state.value ?? [];

    final repository = ref.read(categoryRepositoryProvider);

    final result = await repository.createCategory(
      name: name,
      color: color,
      icon: icon,
      budgetAmount: budgetAmount,
      householdId: int.parse(householdId),
    );

    return result.when(
      (category) {
        state = AsyncData([...previous, category]);
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
    double? budgetAmount,
  }) async {
    final previous = state.value ?? [];

    final repository = ref.read(categoryRepositoryProvider);

    final result = await repository.updateCategory(
      id: id,
      name: name,
      color: color,
      icon: icon,
      budgetAmount: budgetAmount,
    );

    return result.when(
      (updated) {
        final index = previous.indexWhere((c) => c.id == id);
        if (index != -1) {
          previous[index] = updated;
          state = AsyncData(List.from(previous));
        }
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }

  /// Submits a new or updated category.
  /// Returns true on success, false on error.
  Future<bool> submitCategory({
    required String name,
    String? color,
    String? icon,
    double? budgetAmount,
    int? categoryId, // null = create, non-null = update
  }) {
    if (categoryId != null) {
      return updateCategory(
        id: categoryId,
        name: name,
        color: color,
        icon: icon,
        budgetAmount: budgetAmount,
      );
    }
    return createCategory(
      name: name,
      color: color,
      icon: icon,
      budgetAmount: budgetAmount,
    );
  }

  Future<bool> deleteCategory({required int id}) async {
    final previous = state.value ?? [];

    final repository = ref.read(categoryRepositoryProvider);

    final result = await repository.deleteCategory(id: id);
    
    return result.when(
      (_) {
        state = AsyncData(previous.where((c) => c.id != id).toList());
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }
}
