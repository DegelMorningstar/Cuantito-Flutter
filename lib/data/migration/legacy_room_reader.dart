import 'package:sqlite3/sqlite3.dart';

/// Fila cruda de `CategoryEntity` (esquema Room legado).
class LegacyCategory {
  const LegacyCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  final int id;
  final String name;
  final String icon;
}

/// Fila cruda de `MovementEntity` (esquema Room legado).
///
/// `amount` se conserva como `String` (R-01) y `dateTime` en epoch millis; el
/// mapeo a centavos / texto canónico lo hace el servicio de migración.
class LegacyMovement {
  const LegacyMovement({
    required this.id,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.method,
    required this.type,
    required this.dateTime,
  });

  final int id;
  final String amount;
  final String? description;
  final int categoryId;
  final String method;
  final String type;
  final int dateTime;
}

/// Lee la BD Room legada (`cuantito-db-v1`) en SQLite directo, en modo solo
/// lectura (no se modifica ni se borra; el rollback consiste en conservarla
/// intacta hasta validar — F3).
class LegacyRoomReader {
  LegacyRoomReader(this._db);

  /// Abre el archivo SQLite en modo solo lectura.
  factory LegacyRoomReader.open(String path) =>
      LegacyRoomReader(sqlite3.open(path, mode: OpenMode.readOnly));

  final Database _db;

  /// Verdadero si el archivo contiene las dos tablas Room esperadas. Una BD de
  /// otra app o corrupta no las tendrá ⇒ se omite la importación.
  bool hasLegacyTables() {
    final rows = _db.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name IN ('CategoryEntity', 'MovementEntity')",
    );
    return rows.length == 2;
  }

  List<LegacyCategory> readCategories() {
    final rows = _db.select(
      'SELECT id, name, icon FROM CategoryEntity ORDER BY id',
    );
    return [
      for (final r in rows)
        LegacyCategory(
          id: r['id'] as int,
          name: (r['name'] as String?) ?? '',
          icon: (r['icon'] as String?) ?? '',
        ),
    ];
  }

  List<LegacyMovement> readMovements() {
    final rows = _db.select(
      'SELECT id, amount, description, categoryId, method, type, dateTime '
      'FROM MovementEntity ORDER BY id',
    );
    return [
      for (final r in rows)
        LegacyMovement(
          id: r['id'] as int,
          amount: (r['amount'] as String?) ?? '0',
          description: r['description'] as String?,
          categoryId: r['categoryId'] as int,
          method: (r['method'] as String?) ?? '',
          type: (r['type'] as String?) ?? '',
          dateTime: r['dateTime'] as int,
        ),
    ];
  }

  void close() => _db.close();
}
