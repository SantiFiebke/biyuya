import 'package:biyuya/src/core/data/models/user_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfileModel.fromJson', () {
    test('maps all fields', () {
      final model = UserProfileModel.fromJson(const {
        'id': 'u1',
        'name': 'Ana',
        'last_name': 'Perez',
        'household_id': 3,
      });

      expect(model.id, 'u1');
      expect(model.name, 'Ana');
      expect(model.lastName, 'Perez');
      expect(model.householdId, '3');
    });

    test('maps null household_id to null', () {
      final model = UserProfileModel.fromJson(const {
        'id': 'u1',
        'name': 'Ana',
        'last_name': 'Perez',
        'household_id': null,
      });

      expect(model.householdId, isNull);
    });
  });
}
