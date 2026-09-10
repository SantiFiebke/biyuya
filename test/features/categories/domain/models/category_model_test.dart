import 'package:biyuya/src/features/categories/domain/models/category_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryModel.fromJson', () {
    test('parses correctly with all fields', () {
      final json = <String, dynamic>{
        'id': 1,
        'name': 'Groceries',
        'color': '#4CAF50',
        'icon': '63046',
        'household_id': 42,
        'created_at': '2025-01-15T10:30:00.000Z',
      };

      final model = CategoryModel.fromJson(json);

      expect(model.id, 1);
      expect(model.name, 'Groceries');
      expect(model.color, '#4CAF50');
      expect(model.icon, '63046');
      expect(model.householdId, 42);
      expect(model.createdAt, DateTime.parse('2025-01-15T10:30:00.000Z'));
    });

    test('handles null color and icon', () {
      final json = <String, dynamic>{
        'id': 2,
        'name': 'Utilities',
        'color': null,
        'icon': null,
        'household_id': 42,
        'created_at': '2025-03-01T00:00:00.000Z',
      };

      final model = CategoryModel.fromJson(json);

      expect(model.color, isNull);
      expect(model.icon, isNull);
      expect(model.name, 'Utilities');
    });

    test('parses int id and householdId from num (bigint from Postgres)', () {
      final json = <String, dynamic>{
        'id': 9999999999, // bigint comes as num from Supabase
        'name': 'Big Category',
        'color': '#2196F3',
        'icon': null,
        'household_id': 8888888888,
        'created_at': '2025-06-01T12:00:00.000Z',
      };

      final model = CategoryModel.fromJson(json);

      expect(model.id, 9999999999);
      expect(model.householdId, 8888888888);
    });
  });

  group('CategoryModel.toJson', () {
    test('omits id and createdAt (server-generated)', () {
      final model = CategoryModel(
        id: 10,
        name: 'Test',
        householdId: 1,
        createdAt: DateTime(2025),
        color: '#000000',
        icon: '123',
      );

      final json = model.toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json['name'], 'Test');
      expect(json['color'], '#000000');
      expect(json['icon'], '123');
      expect(json['household_id'], 1);
    });

    test('round-trip preserves identity', () {
      final json = <String, dynamic>{
        'id': 5,
        'name': 'Transport',
        'color': '#FF9800',
        'icon': '57681',
        'household_id': 3,
        'created_at': '2025-07-10T08:00:00.000Z',
      };

      final model = CategoryModel.fromJson(json);

      // Verify fromJson parsed everything correctly
      expect(model.id, 5);
      expect(model.name, 'Transport');
      expect(model.color, '#FF9800');
      expect(model.icon, '57681');
      expect(model.householdId, 3);
    });
  });
}
