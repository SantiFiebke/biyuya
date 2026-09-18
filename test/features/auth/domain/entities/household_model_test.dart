import 'package:biyuya/src/features/auth/domain/models/household_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HouseholdModel.fromJson', () {
    test('parses correctly with all fields', () {
      final json = <String, dynamic>{
        'id': 42,
        'name': 'Mi Hogar',
        'invite_code': 'ABC123',
        'created_at': '2025-01-15T10:30:00.000Z',
      };

      final model = HouseholdModel.fromJson(json);

      expect(model.id, '42');
      expect(model.name, 'Mi Hogar');
      expect(model.inviteCode, 'ABC123');
      expect(model.createdAt, DateTime.parse('2025-01-15T10:30:00.000Z'));
    });

    test('handles null invite_code', () {
      final json = <String, dynamic>{
        'id': 7,
        'name': 'Test',
        'invite_code': null,
        'created_at': '2025-03-01T00:00:00.000Z',
      };

      final model = HouseholdModel.fromJson(json);

      expect(model.inviteCode, isNull);
      expect(model.name, 'Test');
    });

    test('parses id from num (bigint from Postgres)', () {
      final json = <String, dynamic>{
        'id': 9999999999,
        'name': 'Big Household',
        'created_at': '2025-06-01T12:00:00.000Z',
      };

      final model = HouseholdModel.fromJson(json);

      expect(model.id, '9999999999');
    });
  });

  group('HouseholdModel.toJson', () {
    test('includes only id and name', () {
      final model = HouseholdModel(
        id: '10',
        name: 'Test',
        createdAt: DateTime(2025),
        inviteCode: 'SECRET',
      );

      final json = model.toJson();

      expect(json['id'], '10');
      expect(json['name'], 'Test');
      expect(json.containsKey('invite_code'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
    });
  });

  group('HouseholdModel roundtrip', () {
    test('fromJson → toJson → fromJson preserves identity fields', () {
      final original = <String, dynamic>{
        'id': 5,
        'name': 'Transport',
        'invite_code': 'CODE99',
        'created_at': '2025-07-10T08:00:00.000Z',
      };

      final model = HouseholdModel.fromJson(original);
      final serialized = model.toJson();
      // ponytail: toJson outputs id as String, fromJson expects num — bridge the gap
      final restored = HouseholdModel.fromJson({
        ...serialized,
        'id': int.parse(serialized['id'] as String),
        'invite_code': model.inviteCode,
        'created_at': original['created_at'],
      });

      expect(restored.id, model.id);
      expect(restored.name, model.name);
      expect(restored.inviteCode, model.inviteCode);
      expect(restored.createdAt, model.createdAt);
    });

    test('round-trip via only toJson loses inviteCode and createdAt', () {
      final model = HouseholdModel(
        id: '1',
        name: 'Home',
        createdAt: DateTime(2025),
        inviteCode: 'XYZ',
      );

      final json = model.toJson();
      // toJson intentionally omits inviteCode and created_at
      expect(json.containsKey('invite_code'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
    });
  });
}
