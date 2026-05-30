import 'package:drift/drift.dart';

/// Categorías de movimientos.
///
/// `name` es **único** (RN-005, antes validado solo en código) e `iconName`
/// guarda el nombre del icono tal cual; el mapeo a `IconData` se resuelve en
/// la capa de presentación (F5, mitiga R-02).
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get iconName => text()();
}

/// Movimientos (ingresos/egresos).
///
/// - `amountCents`: monto en **centavos** (`int`, decisión F0; elimina R-01).
/// - `transactionDate`: instante en **epoch milisegundos**. (Se evita el nombre
///   `dateTime` porque colisiona con un miembro heredado de Drift `Table`.)
/// - `categoryId`: **FK declarada** hacia [Categories] (mitiga R-05).
/// - Índices en `categoryId` y `transactionDate` para las consultas por
///   categoría/mes.
/// - `method`/`type` se guardan como texto (nombre del enum); el parseo
///   tolerante a valores desconocidos se hace al mapear a dominio (F4, R-08).
@TableIndex(name: 'idx_movement_category', columns: {#categoryId})
@TableIndex(name: 'idx_movement_datetime', columns: {#transactionDate})
class Movements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountCents => integer()();
  TextColumn get description => text().nullable()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get method => text()();
  TextColumn get type => text()();
  IntColumn get transactionDate => integer()();
}
