import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

TextTheme createTextTheme(
  BuildContext context,
  String bodyFontString,
  String displayFontString,
) {
  final base = Theme.of(context).textTheme;

  final bodyStyle = GoogleFonts.getFont(bodyFontString);
  final displayStyle = GoogleFonts.getFont(displayFontString);

  return TextTheme(
    displayLarge: displayStyle.copyWith(fontSize: base.displayLarge?.fontSize),
    displayMedium: displayStyle.copyWith(
      fontSize: base.displayMedium?.fontSize,
    ),
    displaySmall: displayStyle.copyWith(fontSize: base.displaySmall?.fontSize),
    headlineLarge: displayStyle.copyWith(
      fontSize: base.headlineLarge?.fontSize,
    ),
    headlineMedium: displayStyle.copyWith(
      fontSize: base.headlineMedium?.fontSize,
    ),
    headlineSmall: displayStyle.copyWith(
      fontSize: base.headlineSmall?.fontSize,
    ),
    titleLarge: displayStyle.copyWith(fontSize: base.titleLarge?.fontSize),
    titleMedium: displayStyle.copyWith(fontSize: base.titleMedium?.fontSize),
    titleSmall: displayStyle.copyWith(fontSize: base.titleSmall?.fontSize),
    bodyLarge: bodyStyle.copyWith(fontSize: base.bodyLarge?.fontSize),
    bodyMedium: bodyStyle.copyWith(fontSize: base.bodyMedium?.fontSize),
    bodySmall: bodyStyle.copyWith(fontSize: base.bodySmall?.fontSize),
    labelLarge: bodyStyle.copyWith(fontSize: base.labelLarge?.fontSize),
    labelMedium: bodyStyle.copyWith(fontSize: base.labelMedium?.fontSize),
    labelSmall: bodyStyle.copyWith(fontSize: base.labelSmall?.fontSize),
  );
}
