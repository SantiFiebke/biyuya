import 'package:biyuya/src/features/categories/data/default_categories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('defaultCategories', () {
    test('has exactly 8 entries', () {
      expect(defaultCategories, hasLength(8));
    });

    test('names are unique and non-empty', () {
      final names = defaultCategories.map((c) => c.name).toList();
      for (final name in names) {
        expect(name.isNotEmpty, isTrue, reason: 'empty name found');
      }
      expect(names.toSet().length, names.length, reason: 'duplicate names');
    });

    test('every color matches hex regex', () {
      final hex = RegExp(r'^#[0-9A-Fa-f]{6}$');
      for (final cat in defaultCategories) {
        expect(
          hex.hasMatch(cat.color),
          isTrue,
          reason: '${cat.name} color "${cat.color}" is invalid hex',
        );
      }
    });

    test('every icon codePoint is > 0', () {
      for (final cat in defaultCategories) {
        expect(cat.icon, greaterThan(0), reason: '${cat.name} icon invalid');
      }
    });

    test('toJson returns name, color, and icon as string', () {
      for (final cat in defaultCategories) {
        final json = cat.toJson();
        expect(json['name'], cat.name);
        expect(json['color'], cat.color);
        expect(json['icon'], cat.icon.toString());
      }
    });
  });
}
