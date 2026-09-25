import 'package:biyuya/src/features/reports/domain/insight_expense_diff.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('classifyInsightExpenses', () {
    test('description not present in previous month tags it nuevo', () {
      final result = classifyInsightExpenses(
        current: [makeExpense(description: 'Netflix')],
        previous: [makeExpense(id: 2, description: 'Spotify')],
      );

      expect(result[1], {ExpenseDiffTag.nuevo});
    });

    test('matching description is not nuevo (case/space insensitive)', () {
      final result = classifyInsightExpenses(
        current: [makeExpense(description: '  Almuerzo ')],
        previous: [makeExpense(id: 2, description: 'ALMUERZO')],
      );

      // Sin etiquetas → el gasto no aparece en el mapa.
      expect(result, isEmpty);
    });

    test('empty description is never nuevo', () {
      final result = classifyInsightExpenses(
        current: [
          makeExpense(description: ''),
          makeExpense(id: 2, description: null),
        ],
        previous: [makeExpense(id: 3, description: 'Spotify')],
      );

      expect(result, isEmpty);
      expect(result.containsKey(1), isFalse);
      expect(result.containsKey(2), isFalse);
    });

    test('amount >= 2x previous average tags it grande', () {
      // Promedio previo 150 → umbral 300. Descripción igual → solo grande.
      final result = classifyInsightExpenses(
        current: [
          makeExpense(amount: 300, description: 'Almuerzo'),
          makeExpense(id: 2, amount: 299, description: 'Almuerzo'),
        ],
        previous: [
          makeExpense(id: 3, description: 'Almuerzo'),
          makeExpense(id: 4, amount: 200, description: 'Almuerzo'),
        ],
      );

      expect(result[1], {ExpenseDiffTag.grande});
      expect(result.containsKey(2), isFalse);
    });

    test('empty previous month tags no expense grande', () {
      final result = classifyInsightExpenses(
        current: [makeExpense(amount: 100000, description: 'Cine')],
        previous: const [],
      );

      // Mes anterior vacío: sin baseline → sin grande (nuevo sí).
      expect(result[1], {ExpenseDiffTag.nuevo});
      expect(result[1]!.contains(ExpenseDiffTag.grande), isFalse);
    });

    test('expense can carry both tags', () {
      final result = classifyInsightExpenses(
        current: [makeExpense(amount: 500, description: 'Netflix')],
        previous: [makeExpense(id: 2, description: 'Spotify')],
      );

      expect(result[1], {ExpenseDiffTag.nuevo, ExpenseDiffTag.grande});
    });

    test('untagged expenses are omitted from the map', () {
      final result = classifyInsightExpenses(
        current: [makeExpense(amount: 150, description: 'Almuerzo')],
        previous: [makeExpense(id: 2, description: 'almuerzo')],
      );

      // Descripción coincide y 150 < 200 (2x promedio) → sin etiquetas.
      expect(result, isEmpty);
      expect(result.containsKey(1), isFalse);
    });
  });
}
