import 'package:biyuya/src/features/categories/domain/entities/category.dart';
import 'package:equatable/equatable.dart';
import 'package:multiple_result/multiple_result.dart';

class CategoryFailure extends Equatable {
  const CategoryFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

abstract class CategoryRepositoryBase {
  /// Obtiene todas las categorías del household del usuario
  Future<Result<List<Category>, CategoryFailure>> getCategories({
    required int householdId,
  });

  /// Crea una nueva categoría
  Future<Result<Category, CategoryFailure>> createCategory({
    required String name,
    required int householdId,
    String? color,
    String? icon,
    double? budgetAmount,
    bool isExpense = true,
  });

  /// Actualiza una categoría existente
  Future<Result<Category, CategoryFailure>> updateCategory({
    required int id,
    required String name,
    String? color,
    String? icon,
    double? budgetAmount,
    bool isExpense = true,
  });

  /// Elimina una categoría
  Future<Result<void, CategoryFailure>> deleteCategory({required int id});
}
