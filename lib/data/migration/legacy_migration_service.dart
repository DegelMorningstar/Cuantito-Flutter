import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../local/app_database.dart';
import '../preferences/preferences_service.dart';
import 'legacy_parsers.dart';
import 'legacy_room_reader.dart';

/// Resuelve la ruta del archivo de la BD Room legada, o `null` si no aplica
/// (otra plataforma, o no se puede determinar).
typedef LegacyDbPathResolver = Future<String?> Function();

/// Resultado de un intento de migración de datos legados.
class LegacyMigrationResult {
  const LegacyMigrationResult({
    required this.ran,
    this.categories = 0,
    this.movements = 0,
    this.skippedMovements = 0,
  });

  /// No había nada que importar (sin BD legada, ya migrado, o sin tablas Room).
  const LegacyMigrationResult.skipped() : this(ran: false);

  /// Verdadero si se importaron datos de una BD legada en este intento.
  final bool ran;
  final int categories;
  final int movements;

  /// Movimientos descartados por apuntar a una categoría inexistente (la FK era
  /// solo lógica en Room, así que podían quedar huérfanos).
  final int skippedMovements;
}

/// Importa, en el primer arranque de la versión Flutter, los datos de la app
/// Android previa (Room `cuantito-db-v1`) al esquema Drift (F3, mitiga R-10).
///
/// - Es idempotente: marca un flag y no reimporta.
/// - No borra la BD legada (plan de rollback: conservarla hasta validar).
/// - Tolerante a montos `String` y enums desconocidos (R-01 / R-08).
class LegacyMigrationService {
  LegacyMigrationService({
    required this.db,
    required this.prefs,
    LegacyDbPathResolver? pathResolver,
  }) : pathResolver = pathResolver ?? defaultLegacyDbPathResolver;

  final AppDatabase db;
  final PreferencesService prefs;
  final LegacyDbPathResolver pathResolver;

  /// Ejecuta la importación si aún no se ha hecho. Siempre marca el flag al
  /// terminar (incluso sin datos) para no reintentar en cada arranque.
  Future<LegacyMigrationResult> migrateIfNeeded() async {
    if (prefs.legacyMigrationDone) return const LegacyMigrationResult.skipped();

    final path = await pathResolver();
    if (path == null || !File(path).existsSync()) {
      await prefs.markLegacyMigrationDone();
      return const LegacyMigrationResult.skipped();
    }

    final reader = LegacyRoomReader.open(path);
    try {
      if (!reader.hasLegacyTables()) {
        await prefs.markLegacyMigrationDone();
        return const LegacyMigrationResult.skipped();
      }
      final result = await _import(reader.readCategories(), reader.readMovements());
      await prefs.markLegacyMigrationDone();
      return result;
    } finally {
      reader.close();
    }
  }

  Future<LegacyMigrationResult> _import(
    List<LegacyCategory> categories,
    List<LegacyMovement> movements,
  ) {
    return db.transaction(() async {
      // Mapa id-legado → id-nuevo. Room no tenía UNIQUE(name), así que los
      // nombres duplicados se consolidan en la primera categoría insertada.
      final idMap = <int, int>{};
      final nameToId = <String, int>{};

      for (final c in categories) {
        final name = c.name.trim();
        if (name.isEmpty) continue; // categoría inválida: se ignora.
        final existing = nameToId[name];
        if (existing != null) {
          idMap[c.id] = existing;
          continue;
        }
        final newId = await db.insertCategory(
          CategoriesCompanion.insert(name: name, iconName: c.icon),
        );
        idMap[c.id] = newId;
        nameToId[name] = newId;
      }

      var imported = 0;
      var skipped = 0;
      for (final m in movements) {
        final newCategoryId = idMap[m.categoryId];
        if (newCategoryId == null) {
          skipped++; // huérfano: sin categoría válida (FK ON lo rechazaría).
          continue;
        }
        await db.insertMovement(
          MovementsCompanion.insert(
            amountCents: parseAmountToCents(m.amount),
            categoryId: newCategoryId,
            method: normalizeMethod(m.method),
            type: normalizeType(m.type),
            transactionDate: m.dateTime,
            description: m.description == null
                ? const Value.absent()
                : Value(m.description),
          ),
        );
        imported++;
      }

      return LegacyMigrationResult(
        ran: true,
        categories: nameToId.length,
        movements: imported,
        skippedMovements: skipped,
      );
    });
  }
}

/// Ruta de la BD Room legada en producción. Solo aplica en Android (la app
/// previa era nativa Android); en otras plataformas devuelve `null`.
///
/// Room guarda en `<dataDir>/databases/<nombre>`. `getApplicationSupportDirectory`
/// devuelve `<dataDir>/files`, cuyo padre es el `dataDir` de la app.
Future<String?> defaultLegacyDbPathResolver() async {
  if (!Platform.isAndroid) return null;
  final support = await getApplicationSupportDirectory();
  final dataDir = p.dirname(support.path);
  return p.join(dataDir, 'databases', 'cuantito-db-v1');
}
