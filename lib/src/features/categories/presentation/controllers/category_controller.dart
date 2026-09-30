// ignore_for_file: async_return_with_no_await — result.when returns directly; async needed for repository await above

import 'dart:async';

import 'package:biyuya/src/core/utils/request_guard.dart';
import 'package:biyuya/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/provider/categories_provider.dart';
import 'package:biyuya/src/features/categories/provider/category_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_controller.g.dart';

@Riverpod(keepAlive: true)
class CategoryController extends _$CategoryController with RequestGuard {
  @override
  AsyncValue<List<Category>> build() {
    invalidateRequests();
    unawaited(Future.microtask(_loadCategories));
    return const AsyncData([]);
  }

  Future<void> _loadCategories() async {
    final token = startRequest();
    state = const AsyncLoading();
    try {
      final categories = await ref.read(categoriesProvider.future);
      if (!ref.mounted) {
        return;
      }
      if (isStale(token)) {
        return;
      }
      state = AsyncData(categories);
    } on Object catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      if (isStale(token)) {
        return;
      }
      state = AsyncError(error, stackTrace);
    }
  }

  Future<bool> createCategory({
    required String name,
    String? color,
    String? icon,
    double? budgetAmount,
    bool isExpense = true,
  }) async {
    final householdId = ref
        .read(authSessionControllerProvider)
        .value
        ?.householdIdValue;
    if (householdId == null) {
      return false;
    }

    final previous = state.value ?? [];

    final repository = ref.read(categoryRepositoryProvider);

    final result = await repository.createCategory(
      name: name,
      color: color,
      icon: icon,
      budgetAmount: budgetAmount,
      householdId: householdId,
      isExpense: isExpense,
    );

    return result.when(
      (category) {
        ref.invalidate(categoriesProvider);
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
    bool isExpense = true,
  }) async {
    final previous = state.value ?? [];

    final repository = ref.read(categoryRepositoryProvider);

    final result = await repository.updateCategory(
      id: id,
      name: name,
      color: color,
      icon: icon,
      budgetAmount: budgetAmount,
      isExpense: isExpense,
    );

    return result.when(
      (updated) {
        ref.invalidate(categoriesProvider);
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
    bool isExpense = true,
  }) {
    if (categoryId != null) {
      return updateCategory(
        id: categoryId,
        name: name,
        color: color,
        icon: icon,
        budgetAmount: budgetAmount,
        isExpense: isExpense,
      );
    }
    return createCategory(
      name: name,
      color: color,
      icon: icon,
      budgetAmount: budgetAmount,
      isExpense: isExpense,
    );
  }

  Future<bool> deleteCategory({required int id}) async {
    final previous = state.value ?? [];

    final repository = ref.read(categoryRepositoryProvider);

    final result = await repository.deleteCategory(id: id);

    return result.when(
      (_) {
        ref.invalidate(categoriesProvider);
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
