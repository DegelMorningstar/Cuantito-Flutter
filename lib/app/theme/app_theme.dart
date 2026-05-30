import 'package:flutter/material.dart';

import 'cuantito_colors.dart';

/// Construye los temas claro/oscuro de Cuantito (Material 3) a partir de un
/// color semilla, e inyecta los colores semánticos [CuantitoColors].
abstract final class AppTheme {
  const AppTheme._();

  /// Color de marca de Cuantito (semilla del [ColorScheme]).
  static const Color seed = Color(0xFF00897B);

  static ThemeData get light => _build(Brightness.light, CuantitoColors.light);

  static ThemeData get dark => _build(Brightness.dark, CuantitoColors.dark);

  static ThemeData _build(Brightness brightness, CuantitoColors colors) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      extensions: <ThemeExtension<dynamic>>[colors],
    );
  }
}
