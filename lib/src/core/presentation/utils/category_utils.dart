import 'package:material_ui/material_ui.dart';

/// Parses a hex color string (e.g. '#FF0000') to [Color].
/// Returns null if [hex] is null, empty, or not a valid 6-char hex.
Color? parseCategoryColor(String? hex) {
  if (hex == null || hex.isEmpty) {
    return null;
  }
  final clean = hex.replaceFirst('#', '');
  if (clean.length != 6) {
    return null;
  }
  return Color(int.parse('FF$clean', radix: 16));
}

/// Converts a code point [String] to [IconData].
/// Returns [Icons.category] if [codePoint] is null or not a valid integer.
IconData iconFromCodePoint(String? codePoint) {
  if (codePoint == null) {
    return Icons.category;
  }
  final cp = int.tryParse(codePoint);
  if (cp == null) {
    return Icons.category;
  }
  // Runtime-parsed icon code from DB cannot be const
  // ignore: non_const_argument_for_const_parameter
  return IconData(cp, fontFamily: 'MaterialIcons');
}
