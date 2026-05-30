import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Base de datos local de Cuantito (Drift sobre SQLite).
///
/// Reemplaza la BD Room `cuantito-db-v1` de la app Android, mejorando el
/// esquema (FK + índices + UNIQUE). Las consultas por mes usan un rango
/// `[inicio, fin)` en epoch calculado en zona local por el llamador, en lugar
/// de `strftime(..., 'unixepoch')` en UTC (mitiga R-04).
@DriftDatabase(tables: [Categories, Movements])
class AppDatabase extends _$AppDatabase {
  /// Constructor de producción (abre la BD en disco). Para tests, pasar un
  /// `NativeDatabase.memory()`.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // SQLite no aplica las FK por defecto; hay que activarlas por conexión.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _open() => driftDatabase(name: 'cuantito');

  // ---------------------------------------------------------------- Categorías
  Future<List<Category>> getAllCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm(expression: c.name)]))
          .get();

  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<Category?> getCategoryByName(String name) =>
      (select(categories)..where((c) => c.name.equals(name))).getSingleOrNull();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  // --------------------------------------------------------------- Movimientos
  Future<int> insertMovement(MovementsCompanion entry) =>
      into(movements).insert(entry);

  Future<Movement?> getMovementById(int id) =>
      (select(movements)..where((m) => m.id.equals(id))).getSingleOrNull();

  Future<int> deleteMovement(int id) =>
      (delete(movements)..where((m) => m.id.equals(id))).go();

  /// Movimientos cuyo `dateTime` cae en `[startMs, endMs)` (epoch millis),
  /// ordenados por fecha descendente. El rango lo calcula el llamador en zona
  /// local (mitiga R-04).
  Future<List<Movement>> getMovementsBetween(int startMs, int endMs) =>
      (select(movements)
            ..where((m) =>
                m.dateTime.isBiggerOrEqualValue(startMs) &
                m.dateTime.isSmallerThanValue(endMs))
            ..orderBy([
              (m) =>
                  OrderingTerm(expression: m.dateTime, mode: OrderingMode.desc),
            ]))
          .get();
}
