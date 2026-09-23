import 'package:biyuya/src/core/network/network_timeout.dart';
import 'package:biyuya/src/features/categories/data/local/category_cache.dart';
import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:biyuya/src/features/categories/domain/models/category_model.dart';
import 'package:biyuya/src/features/categories/domain/repositories/category_repository_base.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class CategoryRepositoryImpl implements CategoryRepositoryBase {
  const CategoryRepositoryImpl(this._client, this._cache);

  final supabase.SupabaseClient _client;
  final CategoryCache _cache;

  @override
  Future<Result<List<Category>, CategoryFailure>> getCategories({
    required int householdId,
  }) async {
    try {
      final data = await _client
          .from('categories')
          .select()
          .eq('household_id', householdId)
          .order('name')
          .timeout(kNetworkTimeout);

      final categories = data.map(CategoryModel.fromJson).toList();
      await _cache.save(categories);
      return Success(categories);
    } on Exception catch (e) {
      final cached = await _cache.load();
      if (cached != null) {
        return Success(cached);
      }
      return Error(CategoryFailure('Error al obtener categorías: $e'));
    }
  }

  @override
  Future<Result<Category, CategoryFailure>> createCategory({
    required String name,
    required int householdId,
    String? color,
    String? icon,
    double? budgetAmount,
  }) async {
    try {
      final data = await _client
          .from('categories')
          .insert({
            'name': name,
            'color': color,
            'icon': icon,
            'household_id': householdId,
            'budget_amount': budgetAmount,
          })
          .select()
          .single()
          .timeout(kNetworkTimeout);

      return Success(CategoryModel.fromJson(data));
    } on Exception catch (e) {
      return Error(CategoryFailure('Error al crear categoría: $e'));
    }
  }

  @override
  Future<Result<Category, CategoryFailure>> updateCategory({
    required int id,
    required String name,
    String? color,
    String? icon,
    double? budgetAmount,
  }) async {
    try {
      final data = await _client
          .from('categories')
          .update({
            'name': name,
            'color': color,
            'icon': icon,
            'budget_amount': budgetAmount,
          })
          .eq('id', id)
          .select()
          .single()
          .timeout(kNetworkTimeout);

      return Success(CategoryModel.fromJson(data));
    } on Exception catch (e) {
      return Error(CategoryFailure('Error al actualizar categoría: $e'));
    }
  }

  @override
  Future<Result<void, CategoryFailure>> deleteCategory({
    required int id,
  }) async {
    try {
      await _client
          .from('categories')
          .delete()
          .eq('id', id)
          .timeout(kNetworkTimeout);
      return const Success(null);
    } on Exception catch (e) {
      return Error(CategoryFailure('Error al eliminar categoría: $e'));
    }
  }
}
