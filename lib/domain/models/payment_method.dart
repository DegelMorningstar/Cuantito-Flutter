/// Método de pago (RN-003). Dominio **puro**: sin color ni iconos (R-07).
///
/// - `storageName`: valor persistido (texto canónico del enum legado).
/// - `label`: etiqueta en español para la UI.
enum PaymentMethod {
  debito('DEBITO', 'Débito'),
  credito('CREDITO', 'Crédito');

  const PaymentMethod(this.storageName, this.label);

  final String storageName;
  final String label;

  /// Parseo **tolerante** desde el texto persistido. Ante un valor desconocido
  /// cae a [debito] en lugar de lanzar (mitiga R-08).
  static PaymentMethod fromStorage(String raw) {
    final up = raw.trim().toUpperCase();
    return values.firstWhere(
      (e) => e.storageName == up,
      orElse: () => debito,
    );
  }

  /// El otro método (para el toggle de NewMovement, RN-003).
  PaymentMethod get toggled => this == debito ? credito : debito;
}
