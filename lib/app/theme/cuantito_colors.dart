import 'package:flutter/material.dart';

/// Colores semánticos de Cuantito que no forman parte del [ColorScheme]
/// estándar de Material: ingreso/egreso (tipo de movimiento) y
/// débito/crédito (método de pago).
///
/// Se exponen como [ThemeExtension] para poder leerlos desde cualquier widget
/// con `Theme.of(context).extension<CuantitoColors>()!` y que respeten el
/// modo claro/oscuro.
@immutable
class CuantitoColors extends ThemeExtension<CuantitoColors> {
  const CuantitoColors({
    required this.income,
    required this.expense,
    required this.debit,
    required this.credit,
  });

  /// Color para ingresos (TransactionType.INGRESO).
  final Color income;

  /// Color para egresos (TransactionType.EGRESO).
  final Color expense;

  /// Color para método débito (PaymentMethod.DEBITO).
  final Color debit;

  /// Color para método crédito (PaymentMethod.CREDITO).
  final Color credit;

  static const light = CuantitoColors(
    income: Color(0xFF2E7D32),
    expense: Color(0xFFC62828),
    debit: Color(0xFF1565C0),
    credit: Color(0xFF6A1B9A),
  );

  static const dark = CuantitoColors(
    income: Color(0xFF81C784),
    expense: Color(0xFFEF9A9A),
    debit: Color(0xFF90CAF9),
    credit: Color(0xFFCE93D8),
  );

  @override
  CuantitoColors copyWith({
    Color? income,
    Color? expense,
    Color? debit,
    Color? credit,
  }) {
    return CuantitoColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
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
    );
  }
}
