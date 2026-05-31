// Tests de integración de la migración Room → Drift (F3).
//
// Construye una BD SQLite con el esquema Room legado (`cuantito-db-v1`) en un
// archivo temporal y verifica que LegacyMigrationService la importa al Drift en
// memoria, además del caso "instalación nueva" (sin BD legada).

import 'dart:io';

import 'package:cuantito/data/local/app_database.dart';
import 'package:cuantito/data/migration/legacy_migration_service.dart';
import 'package:cuantito/data/preferences/preferences_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PreferencesService prefs;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesService(await SharedPreferences.getInstance());
    tempDir = await Directory.systemTemp.createTemp('cuantito_legacy_test');
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Crea un `cuantito-db-v1` de ejemplo con el esquema Room y devuelve su ruta.
  String createLegacyDb({
    required void Function(Database db) seed,
  }) {
    final path = '${tempDir.path}${Platform.pathSeparator}cuantito-db-v1';
    final legacy = sqlite3.open(path);
    legacy.execute('''
      CREATE TABLE CategoryEntity (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL
      );
    ''');
    legacy.execute('''
      CREATE TABLE MovementEntity (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount TEXT NOT NULL,
        description TEXT,
        categoryId INTEGER NOT NULL,
        method TEXT NOT NULL,
        type TEXT NOT NULL,
        dateTime INTEGER NOT NULL
      );
    ''');
    seed(legacy);
    legacy.close();
    return path;
  }

  LegacyMigrationService serviceFor(String? path) => LegacyMigrationService(
        db: db,
        prefs: prefs,
        pathResolver: () async => path,
      );

  test('importa categorías y movimientos de una BD legada', () async {
    final path = createLegacyDb(seed: (legacy) {
      legacy.execute(
        "INSERT INTO CategoryEntity (id, name, icon) VALUES "
        "(1, 'Comida', 'ShoppingCart'), (2, 'Salario', 'Money')",
      );
      legacy.execute(
        "INSERT INTO MovementEntity "
        "(id, amount, description, categoryId, method, type, dateTime) VALUES "
        "(1, '1,234.50', 'Súper', 1, 'DEBITO', 'EGRESO', 1700000000000), "
        "(2, '15000.00', NULL, 2, 'CREDITO', 'INGRESO', 1700100000000)",
      );
    });

    final result = await serviceFor(path).migrateIfNeeded();

    expect(result.ran, true);
    expect(result.categories, 2);
    expect(result.movements, 2);
    expect(result.skippedMovements, 0);
    expect(prefs.legacyMigrationDone, true);

    final cats = await db.getAllCategories();
    expect(cats.map((c) => c.name).toList(), ['Comida', 'Salario']);

    final comida = cats.firstWhere((c) => c.name == 'Comida');
    final movs = await db.getMovementsBetween(0, 2000000000000);
    expect(movs.length, 2);

    final egreso = movs.firstWhere((m) => m.type == 'EGRESO');
    expect(egreso.amountCents, 123450); // "1,234.50" → centavos
    expect(egreso.description, 'Súper');
    expect(egreso.categoryId, comida.id); // FK remapeada correctamente
  });

  test('consolida categorías con nombre duplicado y remapea sus movimientos',
      () async {
    final path = createLegacyDb(seed: (legacy) {
      // Room no tenía UNIQUE(name): pueden existir duplicados.
      legacy.execute(
        "INSERT INTO CategoryEntity (id, name, icon) VALUES "
        "(1, 'Comida', 'ShoppingCart'), (2, 'Comida', 'Food')",
      );
      legacy.execute(
        "INSERT INTO MovementEntity "
        "(id, amount, description, categoryId, method, type, dateTime) VALUES "
        "(1, '10.00', NULL, 1, 'DEBITO', 'EGRESO', 1700000000000), "
        "(2, '20.00', NULL, 2, 'DEBITO', 'EGRESO', 1700100000000)",
      );
    });

    final result = await serviceFor(path).migrateIfNeeded();

    expect(result.categories, 1); // consolidadas
    expect(result.movements, 2);

    final cats = await db.getAllCategories();
    expect(cats.length, 1);
    final movs = await db.getMovementsBetween(0, 2000000000000);
    expect(movs.every((m) => m.categoryId == cats.single.id), true);
  });

  test('descarta movimientos huérfanos (categoría inexistente)', () async {
    final path = createLegacyDb(seed: (legacy) {
      legacy.execute(
        "INSERT INTO CategoryEntity (id, name, icon) VALUES (1, 'Comida', 'X')",
      );
      legacy.execute(
        "INSERT INTO MovementEntity "
        "(id, amount, description, categoryId, method, type, dateTime) VALUES "
        "(1, '10.00', NULL, 1, 'DEBITO', 'EGRESO', 1700000000000), "
        "(2, '20.00', NULL, 99, 'DEBITO', 'EGRESO', 1700100000000)",
      );
    });

    final result = await serviceFor(path).migrateIfNeeded();

    expect(result.movements, 1);
    expect(result.skippedMovements, 1);
  });

  test('enums y montos inválidos no abortan la importación (R-01/R-08)',
      () async {
    final path = createLegacyDb(seed: (legacy) {
      legacy.execute(
        "INSERT INTO CategoryEntity (id, name, icon) VALUES (1, 'Comida', 'X')",
      );
      legacy.execute(
        "INSERT INTO MovementEntity "
        "(id, amount, description, categoryId, method, type, dateTime) VALUES "
        "(1, 'abc', NULL, 1, 'PAYPAL', 'DESCONOCIDO', 1700000000000)",
      );
    });

    final result = await serviceFor(path).migrateIfNeeded();

    expect(result.movements, 1);
    final mov = (await db.getMovementsBetween(0, 2000000000000)).single;
    expect(mov.amountCents, 0); // monto no interpretable → 0
    expect(mov.method, 'DEBITO'); // default
    expect(mov.type, 'EGRESO'); // default
  });

  test('instalación nueva (sin BD legada) no falla y marca el flag', () async {
    final missing = '${tempDir.path}${Platform.pathSeparator}no-existe.db';

    final result = await serviceFor(missing).migrateIfNeeded();

    expect(result.ran, false);
    expect(prefs.legacyMigrationDone, true);
    expect(await db.getAllCategories(), isEmpty);
  });

  test('resolver nulo (otra plataforma) se omite sin error', () async {
    final result = await serviceFor(null).migrateIfNeeded();

    expect(result.ran, false);
    expect(prefs.legacyMigrationDone, true);
  });

  test('es idempotente: no reimporta en un segundo arranque', () async {
    final path = createLegacyDb(seed: (legacy) {
      legacy.execute(
        "INSERT INTO CategoryEntity (id, name, icon) VALUES (1, 'Comida', 'X')",
      );
    });

    await serviceFor(path).migrateIfNeeded();
    final second = await serviceFor(path).migrateIfNeeded();

    expect(second.ran, false);
    expect((await db.getAllCategories()).length, 1); // no se duplica
  });

  test('archivo sin las tablas Room esperadas se omite', () async {
    final path = '${tempDir.path}${Platform.pathSeparator}otra.db';
    final other = sqlite3.open(path);
    other.execute('CREATE TABLE Algo (id INTEGER PRIMARY KEY)');
    other.close();

    final result = await serviceFor(path).migrateIfNeeded();

    expect(result.ran, false);
    expect(prefs.legacyMigrationDone, true);
  });
}
