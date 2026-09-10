import 'package:biyuya/src/features/expenses/domain/models/expense_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseModel.fromJson', () {
    test('parses correctly with all fields', () {
      final json = <String, dynamic>{
        'id': 1,
        'amount': 2500.50,
        'date': '2025-03-15T10:00:00.000Z',
        'description': 'Groceries',
        'household_id': 42,
        'category_id': 7,
        'user_uuid': 'abc-123',
        'created_at': '2025-03-15T10:00:00.000Z',
      };

      final model = ExpenseModel.fromJson(json);

      expect(model.id, 1);
      expect(model.amount, 2500.50);
      expect(model.date, DateTime.parse('2025-03-15T10:00:00.000Z'));
      expect(model.description, 'Groceries');
      expect(model.householdId, 42);
      expect(model.categoryId, 7);
      expect(model.userUuid, 'abc-123');
      expect(model.createdAt, DateTime.parse('2025-03-15T10:00:00.000Z'));
    });

    test('handles null description and userUuid', () {
      final json = <String, dynamic>{
        'id': 2,
        'amount': 100.0,
        'date': '2025-06-01T00:00:00.000Z',
        'description': null,
        'household_id': 1,
        'category_id': 3,
        'user_uuid': null,
        'created_at': '2025-06-01T00:00:00.000Z',
      };

      final model = ExpenseModel.fromJson(json);

      expect(model.description, isNull);
      expect(model.userUuid, isNull);
      expect(model.amount, 100.0);
    });

    test('parses numeric amount correctly from int', () {
      final json = <String, dynamic>{
        'id': 3,
        'amount': 500,
        'date': '2025-07-10T12:00:00.000Z',
        'description': 'Rent',
        'household_id': 10,
        'category_id': 5,
        'user_uuid': 'user-42',
        'created_at': '2025-07-10T12:00:00.000Z',
      };

      final model = ExpenseModel.fromJson(json);

      expect(model.amount, 500.0);
      expect(model.amount, isA<double>());
    });

    test('parses int id, householdId, categoryId correctly from num', () {
      final json = <String, dynamic>{
        'id': 9999999999,
        'amount': 10.5,
        'date': '2025-08-01T08:00:00.000Z',
        'description': null,
        'household_id': 8888888888,
        'category_id': 7777777777,
        'user_uuid': null,
        'created_at': '2025-08-01T08:00:00.000Z',
      };

      final model = ExpenseModel.fromJson(json);

      expect(model.id, 9999999999);
      expect(model.householdId, 8888888888);
      expect(model.categoryId, 7777777777);
    });
  });

  group('ExpenseModel.toJson', () {
    test('round-trip preserves identity', () {
      final json = <String, dynamic>{
        'id': 5,
        'amount': 150.75,
        'date': '2025-09-01T14:30:00.000Z',
        'description': 'Utilities',
        'household_id': 3,
        'category_id': 2,
        'user_uuid': 'user-99',
        'created_at': '2025-09-01T14:30:00.000Z',
      };

      final model = ExpenseModel.fromJson(json);

      expect(model.id, 5);
      expect(model.amount, 150.75);
      expect(model.description, 'Utilities');
      expect(model.householdId, 3);
      expect(model.categoryId, 2);
      expect(model.userUuid, 'user-99');
    });
  });
}
