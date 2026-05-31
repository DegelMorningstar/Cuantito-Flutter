// Widget test de la lista mensual (F7): render de movimientos, totales,
// toggle del resumen, estado vacío y bloqueo de mes futuro (RN-004/RN-007).

import 'package:cuantito/app/theme/app_theme.dart';
import 'package:cuantito/core/di/providers.dart';
import 'package:cuantito/data/local/app_database.dart' show AppDatabase;
import 'package:cuantito/data/repositories/category_repository_impl.dart';
import 'package:cuantito/data/repositories/movement_repository_impl.dart';
import 'package:cuantito/domain/models/category.dart';
import 'package:cuantito/domain/models/movement.dart';
import 'package:cuantito/domain/models/payment_method.dart';
import 'package:cuantito/domain/models/transaction_type.dart';
import 'package:cuantito/presentation/movements/movements_list_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

  Future<Category> seedCategory() async {
    await categoryRepo.add(name: 'Comida', iconName: 'Filled.Restaurant');
    final categories = await categoryRepo.getAll();
    return categories.single;
  }

  Future<void> addMovement({
    required Category category,
    required int amountCents,
    required TransactionType type,
    String? description,
    DateTime? when,
  }) {
    return movementRepo.add(
      Movement(
        id: 0,
        amountCents: amountCents,
        description: description,
        category: category,
        method: PaymentMethod.debito,
        type: type,
        dateTime: when ?? DateTime.now(),
      ),
    );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const MovementsListPage()),
        GoRoute(
          path: '/movements/detail/:id',
          name: 'detail',
          builder: (_, state) =>
              Scaffold(body: Text('detail ${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los movimientos del mes con sus totales', (tester) async {
    final category = await seedCategory();
    await addMovement(
      category: category,
      amountCents: 15000,
      type: TransactionType.egreso,
      description: 'Restaurante',
    );
    await addMovement(
      category: category,
      amountCents: 50000,
      type: TransactionType.ingreso,
    );

    await pumpPage(tester);

    // Item con descripción muestra descripción + nombre de categoría.
    expect(find.text('Restaurante'), findsOneWidget);
    // Item sin descripción muestra el nombre de la categoría.
    expect(find.text('Comida'), findsWidgets);

    // Resumen por defecto: egresos.
    expect(find.text('Total Gastos'), findsOneWidget);
    expect(find.text(r'$150.00'), findsWidgets);
  });

  testWidgets('el toggle del resumen alterna egresos/ingresos', (tester) async {
    final category = await seedCategory();
    await addMovement(
      category: category,
      amountCents: 50000,
      type: TransactionType.ingreso,
    );

    await pumpPage(tester);
    expect(find.text('Total Gastos'), findsOneWidget);

    await tester.tap(find.text('Total Gastos'));
    await tester.pumpAndSettle();

    expect(find.text('Total Ingresos'), findsOneWidget);
    expect(find.text(r'$500.00'), findsWidgets);
  });

  testWidgets('estado vacío cuando no hay movimientos en el mes',
      (tester) async {
    await seedCategory();
    await pumpPage(tester);

    expect(find.text('Sin movimientos este mes'), findsOneWidget);
  });

  testWidgets('el botón de mes siguiente está bloqueado en el mes en curso',
      (tester) async {
    await seedCategory();
    await pumpPage(tester);

    final nextButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_right),
        matching: find.byType(IconButton),
      ),
    );
    expect(nextButton.onPressed, isNull);
  });

  testWidgets('navegar al mes anterior muestra sus movimientos', (tester) async {
    final category = await seedCategory();
    final now = DateTime.now();
    // Movimiento del mes anterior (día 15 para evitar bordes de zona horaria).
    final previousMonth = DateTime(now.year, now.month - 1, 15);
    await addMovement(
      category: category,
      amountCents: 12345,
      type: TransactionType.egreso,
      description: 'Mes pasado',
      when: previousMonth,
    );

    await pumpPage(tester);
    // No aparece en el mes en curso.
    expect(find.text('Mes pasado'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('Mes pasado'), findsOneWidget);
    expect(find.text(r'$123.45'), findsWidgets);
  });
}
