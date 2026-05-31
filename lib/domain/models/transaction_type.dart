/// Tipo de movimiento (RN-003). Dominio **puro**: no expone color ni iconos —
/// la presentación resuelve esos aspectos (mitiga R-07).
///
/// - `storageName`: valor persistido (texto canónico del enum legado).
/// - `label`: etiqueta en español para la UI.
enum TransactionType {
  ingreso('INGRESO', 'Ingreso'),
  egreso('EGRESO', 'Egreso');

  const TransactionType(this.storageName, this.label);

  final String storageName;
  final String label;

  /// Parseo **tolerante** desde el texto persistido. Ante un valor desconocido
  /// cae a [egreso] en lugar de lanzar (mitiga R-08; el `valueOf()` original
  /// reventaba).
  static TransactionType fromStorage(String raw) {
    final up = raw.trim().toUpperCase();
    return values.firstWhere(
      (e) => e.storageName == up,
      orElse: () => egreso,
    );
  }

  /// El otro tipo (para el toggle de NewMovement, RN-003).
  TransactionType get toggled =>
      this == ingreso ? egreso : ingreso;
}
