import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile.householdIdValue', () {
    UserProfile profile(String? householdId) => UserProfile(
      id: 'u1',
      name: 'Test',
      lastName: 'User',
      householdId: householdId,
    );

    test('parses a valid numeric householdId to int', () {
      expect(profile('42').householdIdValue, 42);
    });

    test('returns null when householdId is null', () {
      expect(profile(null).householdIdValue, isNull);
    });

    test('returns null when householdId is empty', () {
      expect(profile('').householdIdValue, isNull);
    });

    test('returns null when householdId is whitespace only', () {
      expect(profile('   ').householdIdValue, isNull);
    });

    test('returns null when householdId is not numeric', () {
      expect(profile('abc').householdIdValue, isNull);
    });
  });
}
