import 'package:material_ui/material_ui.dart';

class MaterialTheme {
  const MaterialTheme(this.textTheme);
  final TextTheme textTheme;

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff286a49),
      surfaceTint: Color(0xff286a49),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffadf2c7),
      onPrimaryContainer: Color(0xff055232),
      secondary: Color(0xff4e6355),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffd0e8d6),
      onSecondaryContainer: Color(0xff374b3e),
      tertiary: Color(0xff006875),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff9eeffe),
      onTertiaryContainer: Color(0xff004f58),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff6fbf4),
      onSurface: Color(0xff171d19),
      onSurfaceVariant: Color(0xff404942),
      outline: Color(0xff717972),
      outlineVariant: Color(0xffc0c9c0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322d),
      inversePrimary: Color(0xff92d5ac),
      primaryFixed: Color(0xffadf2c7),
      onPrimaryFixed: Color(0xff002111),
      primaryFixedDim: Color(0xff92d5ac),
      onPrimaryFixedVariant: Color(0xff055232),
      secondaryFixed: Color(0xffd0e8d6),
      onSecondaryFixed: Color(0xff0b1f14),
      secondaryFixedDim: Color(0xffb5ccbb),
      onSecondaryFixedVariant: Color(0xff374b3e),
      tertiaryFixed: Color(0xff9eeffe),
      onTertiaryFixed: Color(0xff001f24),
      tertiaryFixedDim: Color(0xff82d3e1),
      onTertiaryFixedVariant: Color(0xff004f58),
      surfaceDim: Color(0xffd6dbd5),
      surfaceBright: Color(0xfff6fbf4),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff0f5ee),
      surfaceContainer: Color(0xffeaefe9),
      surfaceContainerHigh: Color(0xffe4eae3),
      surfaceContainerHighest: Color(0xffdfe4dd),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003f25),
      surfaceTint: Color(0xff286a49),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff387956),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff263b2e),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff5c7263),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff003c44),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff197885),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff6fbf4),
      onSurface: Color(0xff0d120f),
      onSurfaceVariant: Color(0xff303832),
      outline: Color(0xff4c554e),
      outlineVariant: Color(0xff676f68),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322d),
      inversePrimary: Color(0xff92d5ac),
      primaryFixed: Color(0xff387956),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff1c603f),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff5c7263),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff455a4c),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff197885),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff005e69),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc3c8c2),
      surfaceBright: Color(0xfff6fbf4),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff0f5ee),
      surfaceContainer: Color(0xffe4eae3),
      surfaceContainerHigh: Color(0xffd9ded8),
      surfaceContainerHighest: Color(0xffced3cd),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff00341e),
      surfaceTint: Color(0xff286a49),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff0a5434),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff1c3024),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff394e40),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff003138),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff00515b),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff6fbf4),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff262e28),
      outlineVariant: Color(0xff434b45),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322d),
      inversePrimary: Color(0xff92d5ac),
      primaryFixed: Color(0xff0a5434),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003b23),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff394e40),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff23372b),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff00515b),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff003940),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb5bab4),
      surfaceBright: Color(0xfff6fbf4),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffedf2eb),
      surfaceContainer: Color(0xffdfe4dd),
      surfaceContainerHigh: Color(0xffd0d6cf),
      surfaceContainerHighest: Color(0xffc3c8c2),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff92d5ac),
      surfaceTint: Color(0xff92d5ac),
      onPrimary: Color(0xff003921),
      primaryContainer: Color(0xff055232),
      onPrimaryContainer: Color(0xffadf2c7),
      secondary: Color(0xffb5ccbb),
      onSecondary: Color(0xff213528),
      secondaryContainer: Color(0xff374b3e),
      onSecondaryContainer: Color(0xffd0e8d6),
      tertiary: Color(0xff82d3e1),
      onTertiary: Color(0xff00363d),
      tertiaryContainer: Color(0xff004f58),
      onTertiaryContainer: Color(0xff9eeffe),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff0f1511),
      onSurface: Color(0xffdfe4dd),
      onSurfaceVariant: Color(0xffc0c9c0),
      outline: Color(0xff8a938b),
      outlineVariant: Color(0xff404942),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdfe4dd),
      inversePrimary: Color(0xff286a49),
      primaryFixed: Color(0xffadf2c7),
      onPrimaryFixed: Color(0xff002111),
      primaryFixedDim: Color(0xff92d5ac),
      onPrimaryFixedVariant: Color(0xff055232),
      secondaryFixed: Color(0xffd0e8d6),
      onSecondaryFixed: Color(0xff0b1f14),
      secondaryFixedDim: Color(0xffb5ccbb),
      onSecondaryFixedVariant: Color(0xff374b3e),
      tertiaryFixed: Color(0xff9eeffe),
      onTertiaryFixed: Color(0xff001f24),
      tertiaryFixedDim: Color(0xff82d3e1),
      onTertiaryFixedVariant: Color(0xff004f58),
      surfaceDim: Color(0xff0f1511),
      surfaceBright: Color(0xff353b36),
      surfaceContainerLowest: Color(0xff0a0f0c),
      surfaceContainerLow: Color(0xff171d19),
      surfaceContainer: Color(0xff1b211d),
      surfaceContainerHigh: Color(0xff262b27),
      surfaceContainerHighest: Color(0xff313632),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffa7ebc1),
      surfaceTint: Color(0xff92d5ac),
      onPrimary: Color(0xff002c19),
      primaryContainer: Color(0xff5c9e78),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffcae2d0),
      onSecondary: Color(0xff162a1e),
      secondaryContainer: Color(0xff809686),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xff98e9f8),
      onTertiary: Color(0xff002a30),
      tertiaryContainer: Color(0xff499caa),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff0f1511),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd6dfd6),
      outline: Color(0xffabb4ac),
      outlineVariant: Color(0xff8a938b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdfe4dd),
      inversePrimary: Color(0xff085333),
      primaryFixed: Color(0xffadf2c7),
      onPrimaryFixed: Color(0xff001509),
      primaryFixedDim: Color(0xff92d5ac),
      onPrimaryFixedVariant: Color(0xff003f25),
      secondaryFixed: Color(0xffd0e8d6),
      onSecondaryFixed: Color(0xff02150a),
      secondaryFixedDim: Color(0xffb5ccbb),
      onSecondaryFixedVariant: Color(0xff263b2e),
      tertiaryFixed: Color(0xff9eeffe),
      onTertiaryFixed: Color(0xff001418),
      tertiaryFixedDim: Color(0xff82d3e1),
      onTertiaryFixedVariant: Color(0xff003c44),
      surfaceDim: Color(0xff0f1511),
      surfaceBright: Color(0xff404641),
      surfaceContainerLowest: Color(0xff040806),
      surfaceContainerLow: Color(0xff191f1b),
      surfaceContainer: Color(0xff242925),
      surfaceContainerHigh: Color(0xff2e3430),
      surfaceContainerHighest: Color(0xff393f3a),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffbcffd5),
      surfaceTint: Color(0xff92d5ac),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff8ed1a8),
      onPrimaryContainer: Color(0xff000e06),
      secondary: Color(0xffdef6e3),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffb1c8b7),
      onSecondaryContainer: Color(0xff000e06),
      tertiary: Color(0xffcff7ff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xff7ecfdd),
      onTertiaryContainer: Color(0xff000e10),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff0f1511),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffeaf2e9),
      outlineVariant: Color(0xffbcc5bc),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdfe4dd),
      inversePrimary: Color(0xff085333),
      primaryFixed: Color(0xffadf2c7),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff92d5ac),
      onPrimaryFixedVariant: Color(0xff001509),
      secondaryFixed: Color(0xffd0e8d6),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffb5ccbb),
      onSecondaryFixedVariant: Color(0xff02150a),
      tertiaryFixed: Color(0xff9eeffe),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xff82d3e1),
      onTertiaryFixedVariant: Color(0xff001418),
      surfaceDim: Color(0xff0f1511),
      surfaceBright: Color(0xff4c514d),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1b211d),
      surfaceContainer: Color(0xff2c322d),
      surfaceContainerHigh: Color(0xff373d38),
      surfaceContainerHighest: Color(0xff424843),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
  );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
  final Color seed;
  final Color value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
