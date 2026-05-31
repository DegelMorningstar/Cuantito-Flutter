// Lógica de NewMovement (teclado RN-002, toggles RN-003, validación RN-001,
// reset parcial RN-010).

import 'package:cuantito/core/di/providers.dart';
import 'package:cuantito/data/local/app_database.dart' show AppDatabase;
import 'package:cuantito/domain/models/category.dart';
import 'package:cuantito/domain/models/payment_method.dart';
import 'package:cuantito/domain/models/transaction_type.dart';
import 'package:cuantito/presentation/newmovement/new_movement_notifier.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late NewMovementNotifier notifier;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    notifier = container.read(newMovementProvider.notifier);
  });

  tearDown(() {
    container.dispose();
    return db.close();
  });

  String currentAmount() => container.read(newMovementProvider).amount;

  Future<Category> seedCategory() async {
    final repo = container.read(categoryRepositoryProvider);
    final id = await repo.add(name: 'Comida', iconName: 'Filled.Restaurant');
    return (await repo.getById(id))!;
  }

  group('teclado (RN-002)', () {
    test('un dígito reemplaza el 0.00 inicial y luego concatena', () {
      notifier.onKey('5');
      expect(currentAmount(), '5');
      notifier.onKey('0');
      expect(currentAmount(), '50');
    });

    test('solo permite un punto decimal', () {
      notifier.onKey('5');
      notifier.onKey('.');
      expect(currentAmount(), '5.');
      notifier.onKey('.'); // ignorado
      expect(currentAmount(), '5.');
      notifier.onKey('0');
      expect(currentAmount(), '5.0');
    });

    test('backspace borra y al final vuelve a 0.00', () {
      notifier.onKey('5');
      notifier.onKey('0');
      expect(currentAmount(), '50');
      notifier.onBackspace();
      expect(currentAmount(), '5');
      notifier.onBackspace(); // queda 1 carácter → 0.00
      expect(currentAmount(), '0.00');
      notifier.onBackspace(); // ya en 0.00, se mantiene
      expect(currentAmount(), '0.00');
    });
  });

  group('toggles (RN-003)', () {
    test('tipo y método alternan', () {
      expect(container.read(newMovementProvider).type, TransactionType.egreso);
      notifier.toggleType();
      expect(container.read(newMovementProvider).type, TransactionType.ingreso);

      expect(container.read(newMovementProvider).method, PaymentMethod.debito);
      notifier.toggleMethod();
      expect(container.read(newMovementProvider).method, PaymentMethod.credito);
    });
  });

  group('save', () {
    test('monto cero es inválido (RN-001) y no persiste', () async {
      final result = await notifier.save();
      expect(result, SaveResult.invalidAmount);
      expect(await container.read(movementRepositoryProvider).getAll(), isEmpty);
    });

    test('sin categoría real devuelve noCategory', () async {
      notifier.onKey('1');
      notifier.onKey('5');
      notifier.onKey('0');
      expect(await notifier.save(), SaveResult.noCategory);
    });

    test('guarda, convierte a centavos y hace reset parcial (RN-010)',
        () async {
      final category = await seedCategory();
      notifier
        ..setCategory(category)
        ..toggleType() // ingreso
        ..setDescription('Quincena')
        ..onKey('1')
        ..onKey('5')
        ..onKey('0')
        ..onKey('.')
        ..onKey('5')
        ..onKey('0'); // "150.50"

      final result = await notifier.save();
      expect(result, SaveResult.success);

      final movements =
          await container.read(movementRepositoryProvider).getAll();
      expect(movements.length, 1);
      expect(movements.single.amountCents, 15050);
      expect(movements.single.type, TransactionType.ingreso);
      expect(movements.single.description, 'Quincena');

      // Reset parcial: monto y descripción se limpian; tipo/método/categoría no.
      final state = container.read(newMovementProvider);
      expect(state.amount, '0.00');
      expect(state.description, '');
      expect(state.type, TransactionType.ingreso);
      expect(state.category, category);
    });
  });
}
