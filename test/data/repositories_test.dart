// Integración de los repositorios sobre Drift en memoria: mapeo entity↔dominio,
// join movimiento→categoría, filtro mensual y totales (RN-005, RN-007, R-04).

import 'package:cuantito/data/local/app_database.dart' show AppDatabase;
import 'package:cuantito/data/repositories/category_repository_impl.dart';
import 'package:cuantito/data/repositories/movement_repository_impl.dart';
import 'package:cuantito/domain/models/category.dart';
import 'package:cuantito/domain/models/movement.dart';
import 'package:cuantito/domain/models/payment_method.dart';
import 'package:cuantito/domain/models/transaction_type.dart';
import 'package:cuantito/domain/rules/month_rules.dart';
import 'package:cuantito/domain/usecases/category_usecases.dart';
import 'package:cuantito/domain/usecases/movement_usecases.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CategoryRepositoryImpl categoryRepo;
  late MovementRepositoryImpl movementRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    categoryRepo = CategoryRepositoryImpl(db);
    movementRepo = MovementRepositoryImpl(db);
  });

  tearDown(() => db.close());

  Future<Category> seedCategory([String name = 'Comida']) async {
    final id = await categoryRepo.add(name: name, iconName: 'ShoppingCart');
    return (await categoryRepo.getById(id))!;
  }

  Movement movementOf(
    Category category, {
    required int cents,
    TransactionType type = TransactionType.egreso,
    DateTime? when,
  }) =>
      Movement(
        id: 0,
        amountCents: cents,
        description: 'desc',
        category: category,
        method: PaymentMethod.debito,
        type: type,
        dateTime: when ?? DateTime(2026, 5, 15),
      );

  test('AddCategory persiste y AddCategory duplicado falla (RN-005)', () async {
    final addCategory = AddCategory(categoryRepo);
    await addCategory(name: 'Salario', iconName: 'Money');

    expect(await categoryRepo.existsByName('Salario'), isTrue);
    expect(
      () => addCategory(name: 'Salario', iconName: 'Money'),
      throwsA(isA<Exception>()),
    );
  });

  test('AddMovement persiste y getById trae la categoría unida', () async {
    final cat = await seedCategory();
    final id = await AddMovement(movementRepo)(movementOf(cat, cents: 5000));

    final loaded = await movementRepo.getById(id);
    expect(loaded, isNotNull);
    expect(loaded!.amountCents, 5000);
    expect(loaded.category, cat); // join correcto
    expect(loaded.type, TransactionType.egreso);
    expect(loaded.method, PaymentMethod.debito);
  });

  test('getByMonth filtra por mes local y une categorías (R-04)', () async {
    final cat = await seedCategory();
    final add = AddMovement(movementRepo);
    await add(movementOf(cat, cents: 100, when: DateTime(2026, 4, 30, 23, 59)));
    await add(movementOf(cat, cents: 200, when: DateTime(2026, 5, 1)));
    await add(movementOf(cat, cents: 300, when: DateTime(2026, 5, 31, 23, 59)));
    await add(movementOf(cat, cents: 400, when: DateTime(2026, 6, 1)));

    final mayo = await GetMovementsByMonth(movementRepo)(2026, 5);
    expect(mayo.map((m) => m.amountCents).toList(), [300, 200]); // fecha desc
    expect(mayo.every((m) => m.category == cat), isTrue);
  });

  test('computeMonthTotals sobre datos reales (RN-007)', () async {
    final cat = await seedCategory();
    final add = AddMovement(movementRepo);
    await add(movementOf(cat, cents: 10000, type: TransactionType.ingreso));
    await add(movementOf(cat, cents: 2500, type: TransactionType.egreso));

    final totals = computeMonthTotals(
      await GetMovementsByMonth(movementRepo)(2026, 5),
    );
    expect(totals.incomeCents, 10000);
    expect(totals.expenseCents, 2500);
  });

  test('DeleteMovement elimina el registro', () async {
    final cat = await seedCategory();
    final id = await AddMovement(movementRepo)(movementOf(cat, cents: 500));

    expect(await DeleteMovement(movementRepo)(id), 1);
    expect(await movementRepo.getById(id), isNull);
  });
}
