import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cuantito_colors.dart';

/// Temas de Cuantito (Material 3). El rediseño es **oscuro** (token `bg`
/// `#0A0B0F`, tipografía **Space Grotesk**, acentos coral/verde por tipo de
/// movimiento). Se conserva un tema claro estructural para los widget tests.
abstract final class AppTheme {
  const AppTheme._();

  /// Fondo base del diseño (token `bg`).
  static const Color background = Color(0xFF0A0B0F);

  /// Texto principal (token `text`).
  static const Color onBackground = Color(0xFFECEDF6);

  /// Acento de marca (coral del egreso); semilla del [ColorScheme].
  static const Color seed = Color(0xFFDA5237);

  static ThemeData get dark => _buildDark();

  static ThemeData get light => _buildLight();

  /// Aplica Space Grotesk al [TextTheme] base con el color de texto dado.
  static TextTheme _spaceGrotesk(TextTheme base, Color color) =>
      GoogleFonts.spaceGroteskTextTheme(base).apply(
        bodyColor: color,
        displayColor: color,
      );

  static ThemeData _buildDark() {
    final c = CuantitoColors.dark;
    final scheme =
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark)
            .copyWith(
      surface: background,
      onSurface: onBackground,
      primary: seed,
      onSurfaceVariant: c.textMedium,
      outline: c.hairline,
      outlineVariant: c.hairline,
      surfaceContainerLowest: background,
      surfaceContainerLow: c.surface1,
      surfaceContainer: c.surface1,
      surfaceContainerHigh: c.surface2,
      surfaceContainerHighest: c.surface3,
    );

    final textTheme =
        _spaceGrotesk(ThemeData(brightness: Brightness.dark).textTheme, onBackground);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      canvasColor: background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: onBackground,
      ),
      cardTheme: CardThemeData(
        color: c.surface1,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.hairline, thickness: 1, space: 1),
      extensions: <ThemeExtension<dynamic>>[c],
    );
  }

  static ThemeData _buildLight() {
    final c = CuantitoColors.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00897B),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _spaceGrotesk(
        ThemeData(brightness: Brightness.light).textTheme,
        scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      extensions: <ThemeExtension<dynamic>>[c],
    );
  }
}
