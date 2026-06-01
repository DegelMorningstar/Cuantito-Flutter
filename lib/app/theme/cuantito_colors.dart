import 'package:flutter/material.dart';

/// Colores semánticos y de superficie de Cuantito que no forman parte del
/// [ColorScheme] estándar de Material.
///
/// Incluye los tokens del rediseño (capa de presentación): superficies
/// elevadas (`surface1/2/3`), línea divisoria (`hairline`) y tintes de texto
/// (`textMedium`/`textDim`), además de los colores por tipo de movimiento
/// (ingreso/egreso) y método de pago (débito/crédito).
///
/// Se exponen como [ThemeExtension] para leerlos desde cualquier widget con
/// `Theme.of(context).extension<CuantitoColors>()!`.
@immutable
class CuantitoColors extends ThemeExtension<CuantitoColors> {
  const CuantitoColors({
    required this.income,
    required this.expense,
    required this.debit,
    required this.credit,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.hairline,
    required this.textMedium,
    required this.textDim,
  });

  /// Color para ingresos (TransactionType.ingreso).
  final Color income;

  /// Color para egresos (TransactionType.egreso).
  final Color expense;

  /// Color para método débito (PaymentMethod.debito).
  final Color debit;

  /// Color para método crédito (PaymentMethod.credito).
  final Color credit;

  /// Superficie base elevada (cards, chips, inputs) — token `s1` del diseño.
  final Color surface1;

  /// Superficie más elevada (teclas, tiles de ícono) — token `s2`.
  final Color surface2;

  /// Superficie en estado presionado — token `s3`.
  final Color surface3;

  /// Línea divisoria sutil (bordes/hairlines).
  final Color hairline;

  /// Texto secundario (≈52% de opacidad sobre el texto principal).
  final Color textMedium;

  /// Texto terciario/atenuado (≈28%).
  final Color textDim;

  /// Paleta del rediseño (oscuro). Es la usada por la app.
  static const dark = CuantitoColors(
    income: Color(0xFF37B26C), // sage green (rgb 55,178,108)
    expense: Color(0xFFDA5237), // warm coral-red (rgb 218,82,55)
    debit: Color(0xFF90CAF9),
    credit: Color(0xFFCE93D8),
    surface1: Color(0xFF13141A),
    surface2: Color(0xFF1C1D25),
    surface3: Color(0xFF252630),
    hairline: Color(0x12FFFFFF), // white @ ~7%
    textMedium: Color(0x85ECEDF6), // text @ ~52%
    textDim: Color(0x47ECEDF6), // text @ ~28%
  );

  /// Variante clara (estructuralmente válida; la app fuerza el tema oscuro, se
  /// conserva para los widget tests que montan `AppTheme.light`).
  static const light = CuantitoColors(
    income: Color(0xFF2E7D32),
    expense: Color(0xFFC62828),
    debit: Color(0xFF1565C0),
    credit: Color(0xFF6A1B9A),
    surface1: Color(0xFFF2F3F7),
    surface2: Color(0xFFE7E9F0),
    surface3: Color(0xFFDADCE6),
    hairline: Color(0x141A1B2E),
    textMedium: Color(0x99101114),
    textDim: Color(0x55101114),
  );

  @override
  CuantitoColors copyWith({
    Color? income,
    Color? expense,
    Color? debit,
    Color? credit,
    Color? surface1,
    Color? surface2,
    Color? surface3,
    Color? hairline,
    Color? textMedium,
    Color? textDim,
  }) {
    return CuantitoColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      surface1: surface1 ?? this.surface1,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      hairline: hairline ?? this.hairline,
      textMedium: textMedium ?? this.textMedium,
      textDim: textDim ?? this.textDim,
    );
  }

  @override
  CuantitoColors lerp(ThemeExtension<CuantitoColors>? other, double t) {
    if (other is! CuantitoColors) return this;
    return CuantitoColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      debit: Color.lerp(debit, other.debit, t)!,
      credit: Color.lerp(credit, other.credit, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      textMedium: Color.lerp(textMedium, other.textMedium, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
    );
  }
}
