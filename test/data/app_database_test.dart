// Tests de integración de la capa de datos (Drift) en BD en memoria (F2).

import 'package:cuantito/data/local/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedCategory({
    String name = 'Comida',
    String icon = 'ShoppingCart',
  }) {
    return db.insertCategory(
      CategoriesCompanion.insert(name: name, iconName: icon),
    );
  }

  test('inserta y lee una categoría', () async {
    final id = await seedCategory();
    final cat = await db.getCategoryById(id);

    expect(cat, isNotNull);
    expect(cat!.name, 'Comida');
    expect(cat.iconName, 'ShoppingCart');
  });

  test('el nombre de categoría es único (RN-005)', () async {
    await seedCategory(name: 'Salario');

    expect(
      () => seedCategory(name: 'Salario'),
      throwsA(isA<Exception>()),
    );
  });

  test('getAllCategories ordena por nombre', () async {
    await seedCategory(name: 'Zapatos', icon: 'Shoe');
    await seedCategory(name: 'Auto', icon: 'Car');
    await seedCategory(name: 'Mascota', icon: 'Pet');

    final names = (await db.getAllCategories()).map((c) => c.name).toList();
    expect(names, ['Auto', 'Mascota', 'Zapatos']);
  });

  test('inserta, lee y borra un movimiento', () async {
    final catId = await seedCategory();
    final id = await db.insertMovement(
      MovementsCompanion.insert(
        amountCents: 123450,
        categoryId: catId,
        method: 'DEBITO',
        type: 'EGRESO',
        transactionDate: DateTime(2026, 5, 15).millisecondsSinceEpoch,
        description: const Value('Súper'),
      ),
    );

    final m = await db.getMovementById(id);
    expect(m, isNotNull);
    expect(m!.amountCents, 123450);
    expect(m.description, 'Súper');

    final deleted = await db.deleteMovement(id);
    expect(deleted, 1);
    expect(await db.getMovementById(id), isNull);
  });

  test('una FK inválida es rechazada (foreign_keys ON)', () async {
    expect(
      () => db.insertMovement(
        MovementsCompanion.insert(
          amountCents: 100,
          categoryId: 999, // no existe
          method: 'DEBITO',
          type: 'EGRESO',
          transactionDate: DateTime(2026, 5, 15).millisecondsSinceEpoch,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('getMovementsBetween usa rango local [inicio, fin) y ordena desc (R-04)',
      () async {
    final catId = await seedCategory();

    Future<void> add(DateTime dt, int cents) async {
      await db.insertMovement(
        MovementsCompanion.insert(
          amountCents: cents,
          categoryId: catId,
          method: 'DEBITO',
          type: 'EGRESO',
          transactionDate: dt.millisecondsSinceEpoch,
        ),
      );
    }

    // Mes objetivo: mayo 2026 (zona local).
    final start = DateTime(2026, 5, 1);
    final end = DateTime(2026, 6, 1);

    await add(DateTime(2026, 4, 30, 23, 59), 1); // fuera (antes del inicio)
    await add(DateTime(2026, 5, 1, 0, 0), 2); // dentro (límite inferior incl.)
    await add(DateTime(2026, 5, 31, 23, 59), 3); // dentro
    await add(DateTime(2026, 6, 1, 0, 0), 4); // fuera (límite superior excl.)

    final result = await db.getMovementsBetween(
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    );

    // Solo los dos de mayo, ordenados por fecha descendente.
    expect(result.map((m) => m.amountCents).toList(), [3, 2]);
  });
}
