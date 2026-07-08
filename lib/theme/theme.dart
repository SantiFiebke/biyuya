import 'package:flutter/material.dart';

class MaterialTheme {
  const MaterialTheme(this.textTheme);

  final TextTheme textTheme;

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff186b53),
      surfaceTint: Color(0xff186b53),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffa5f2d3),
      onPrimaryContainer: Color(0xff00513d),
      secondary: Color(0xff4c6359),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffcee9db),
      onSecondaryContainer: Color(0xff344c42),
      tertiary: Color(0xff3f6375),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffc2e8fd),
      onTertiaryContainer: Color(0xff264b5c),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff5fbf6),
      onSurface: Color(0xff171d1a),
      onSurfaceVariant: Color(0xff404944),
      outline: Color(0xff707974),
      outlineVariant: Color(0xffbfc9c3),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322f),
      inversePrimary: Color(0xff89d6b8),
      primaryFixed: Color(0xffa5f2d3),
      onPrimaryFixed: Color(0xff002117),
      primaryFixedDim: Color(0xff89d6b8),
      onPrimaryFixedVariant: Color(0xff00513d),
      secondaryFixed: Color(0xffcee9db),
      onSecondaryFixed: Color(0xff082018),
      secondaryFixedDim: Color(0xffb3ccc0),
      onSecondaryFixedVariant: Color(0xff344c42),
      tertiaryFixed: Color(0xffc2e8fd),
      onTertiaryFixed: Color(0xff001e2b),
      tertiaryFixedDim: Color(0xffa7cce1),
      onTertiaryFixedVariant: Color(0xff264b5c),
      surfaceDim: Color(0xffd5dbd7),
      surfaceBright: Color(0xfff5fbf6),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff5f0),
      surfaceContainer: Color(0xffe9efea),
      surfaceContainerHigh: Color(0xffe4eae5),
      surfaceContainerHighest: Color(0xffdee4df),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003e2e),
      surfaceTint: Color(0xff186b53),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff2c7a61),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff243b32),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff5a7268),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff133a4b),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff4e7284),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fbf6),
      onSurface: Color(0xff0d1210),
      onSurfaceVariant: Color(0xff2f3834),
      outline: Color(0xff4b5550),
      outlineVariant: Color(0xff666f6a),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322f),
      inversePrimary: Color(0xff89d6b8),
      primaryFixed: Color(0xff2c7a61),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff056149),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff5a7268),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff425a50),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff4e7284),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff35596b),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc2c8c3),
      surfaceBright: Color(0xfff5fbf6),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff5f0),
      surfaceContainer: Color(0xffe4eae5),
      surfaceContainerHigh: Color(0xffd8ded9),
      surfaceContainerHighest: Color(0xffcdd3ce),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003325),
      surfaceTint: Color(0xff186b53),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff00543f),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff1a3028),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff374e44),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff043040),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff294d5f),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fbf6),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff252e2a),
      outlineVariant: Color(0xff424b47),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322f),
      inversePrimary: Color(0xff89d6b8),
      primaryFixed: Color(0xff00543f),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003b2b),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff374e44),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff20372e),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff294d5f),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff0e3747),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb4bab6),
      surfaceBright: Color(0xfff5fbf6),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffecf2ed),
      surfaceContainer: Color(0xffdee4df),
      surfaceContainerHigh: Color(0xffd0d6d1),
      surfaceContainerHighest: Color(0xffc2c8c3),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff89d6b8),
      surfaceTint: Color(0xff89d6b8),
      onPrimary: Color(0xff003829),
      primaryContainer: Color(0xff00513d),
      onPrimaryContainer: Color(0xffa5f2d3),
      secondary: Color(0xffb3ccc0),
      onSecondary: Color(0xff1e352c),
      secondaryContainer: Color(0xff344c42),
      onSecondaryContainer: Color(0xffcee9db),
      tertiary: Color(0xffa7cce1),
      onTertiary: Color(0xff0b3445),
      tertiaryContainer: Color(0xff264b5c),
      onTertiaryContainer: Color(0xffc2e8fd),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff0f1512),
      onSurface: Color(0xffdee4df),
      onSurfaceVariant: Color(0xffbfc9c3),
      outline: Color(0xff89938d),
      outlineVariant: Color(0xff404944),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4df),
      inversePrimary: Color(0xff186b53),
      primaryFixed: Color(0xffa5f2d3),
      onPrimaryFixed: Color(0xff002117),
      primaryFixedDim: Color(0xff89d6b8),
      onPrimaryFixedVariant: Color(0xff00513d),
      secondaryFixed: Color(0xffcee9db),
      onSecondaryFixed: Color(0xff082018),
      secondaryFixedDim: Color(0xffb3ccc0),
      onSecondaryFixedVariant: Color(0xff344c42),
      tertiaryFixed: Color(0xffc2e8fd),
      onTertiaryFixed: Color(0xff001e2b),
      tertiaryFixedDim: Color(0xffa7cce1),
      onTertiaryFixedVariant: Color(0xff264b5c),
      surfaceDim: Color(0xff0f1512),
      surfaceBright: Color(0xff343b37),
      surfaceContainerLowest: Color(0xff0a0f0d),
      surfaceContainerLow: Color(0xff171d1a),
      surfaceContainer: Color(0xff1b211e),
      surfaceContainerHigh: Color(0xff252b28),
      surfaceContainerHighest: Color(0xff303633),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff9feccd),
      surfaceTint: Color(0xff89d6b8),
      onPrimary: Color(0xff002c1f),
      primaryContainer: Color(0xff539e83),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffc8e2d5),
      onSecondary: Color(0xff132a21),
      secondaryContainer: Color(0xff7d968b),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffbce2f7),
      onTertiary: Color(0xff002939),
      tertiaryContainer: Color(0xff7296a9),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff0f1512),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd5dfd8),
      outline: Color(0xffaab4ae),
      outlineVariant: Color(0xff89938d),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4df),
      inversePrimary: Color(0xff00523e),
      primaryFixed: Color(0xffa5f2d3),
      onPrimaryFixed: Color(0xff00150d),
      primaryFixedDim: Color(0xff89d6b8),
      onPrimaryFixedVariant: Color(0xff003e2e),
      secondaryFixed: Color(0xffcee9db),
      onSecondaryFixed: Color(0xff00150e),
      secondaryFixedDim: Color(0xffb3ccc0),
      onSecondaryFixedVariant: Color(0xff243b32),
      tertiaryFixed: Color(0xffc2e8fd),
      onTertiaryFixed: Color(0xff00131d),
      tertiaryFixedDim: Color(0xffa7cce1),
      onTertiaryFixedVariant: Color(0xff133a4b),
      surfaceDim: Color(0xff0f1512),
      surfaceBright: Color(0xff404642),
      surfaceContainerLowest: Color(0xff040806),
      surfaceContainerLow: Color(0xff191f1c),
      surfaceContainer: Color(0xff232926),
      surfaceContainerHigh: Color(0xff2e3431),
      surfaceContainerHighest: Color(0xff393f3c),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffb7ffe1),
      surfaceTint: Color(0xff89d6b8),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff86d2b4),
      onPrimaryContainer: Color(0xff000e08),
      secondary: Color(0xffdcf6e9),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffafc8bc),
      onSecondaryContainer: Color(0xff000e08),
      tertiary: Color(0xffe0f3ff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffa3c8dd),
      onTertiaryContainer: Color(0xff000d14),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff0f1512),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffe9f2ec),
      outlineVariant: Color(0xffbbc5bf),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4df),
      inversePrimary: Color(0xff00523e),
      primaryFixed: Color(0xffa5f2d3),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff89d6b8),
      onPrimaryFixedVariant: Color(0xff00150d),
      secondaryFixed: Color(0xffcee9db),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffb3ccc0),
      onSecondaryFixedVariant: Color(0xff00150e),
      tertiaryFixed: Color(0xffc2e8fd),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffa7cce1),
      onTertiaryFixedVariant: Color(0xff00131d),
      surfaceDim: Color(0xff0f1512),
      surfaceBright: Color(0xff4b514e),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1b211e),
      surfaceContainer: Color(0xff2c322f),
      surfaceContainerHigh: Color(0xff373d39),
      surfaceContainerHighest: Color(0xff424845),
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
