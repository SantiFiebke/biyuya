import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';

/// Etiqueta de diferencia entre el mes actual y el anterior.
enum ExpenseDiffTag {
  /// Descripción que no existía en el mes anterior.
  nuevo,

  /// Monto >= 2x el promedio del mes anterior.
  grande,
}

/// Clasifica los gastos del mes actual contra los del mes anterior.
///
/// Reglas:
/// - [ExpenseDiffTag.nuevo]: gasto actual cuya descripción normalizada
///   (trim + minúsculas) no coincide con ninguna descripción de los gastos
///   del mes anterior. Gastos con descripción vacía nunca son `nuevo`.
/// - [ExpenseDiffTag.grande]: gasto actual con monto >= 2x el promedio de
///   los montos del mes anterior. Si el mes anterior está vacío, ningún
///   gasto es `grande`.
/// - Un gasto puede tener ambas etiquetas.
///
/// Devuelve un mapa `expense.id -> tags`. Gastos sin etiquetas no aparecen.
/// Función pura: sin dependencias de Flutter ni estado.
Map<int, Set<ExpenseDiffTag>> classifyInsightExpenses({
  required List<Expense> current,
  required List<Expense> previous,
}) {
  final previousDescriptions = previous
      .map((e) => (e.description ?? '').trim().toLowerCase())
      .toSet();
  final previousAverage = previous.isEmpty
      ? 0.0
      : previous.fold<double>(0, (sum, e) => sum + e.amount) / previous.length;

  final result = <int, Set<ExpenseDiffTag>>{};
  for (final expense in current) {
    final tags = <ExpenseDiffTag>{};

    final description = (expense.description ?? '').trim().toLowerCase();
    if (description.isNotEmpty && !previousDescriptions.contains(description)) {
      tags.add(ExpenseDiffTag.nuevo);
    }

    if (previous.isNotEmpty && expense.amount >= previousAverage * 2) {
      tags.add(ExpenseDiffTag.grande);
    }

    if (tags.isNotEmpty) {
      result[expense.id] = tags;
    }
  }
  return result;
}
