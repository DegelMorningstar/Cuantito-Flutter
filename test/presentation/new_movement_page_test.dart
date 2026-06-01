// Widget test de NewMovement: registrar end-to-end y bloquear monto inválido.

import 'package:cuantito/app/theme/app_theme.dart';
import 'package:cuantito/core/di/providers.dart';
import 'package:cuantito/data/local/app_database.dart' show AppDatabase;
import 'package:cuantito/data/repositories/category_repository_impl.dart';
import 'package:cuantito/data/repositories/movement_repository_impl.dart';
import 'package:cuantito/presentation/newmovement/new_movement_page.dart';
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

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const NewMovementPage()),
        GoRoute(
          path: '/movements',
          name: 'movements',
          builder: (_, _) => const Scaffold(body: Text('movements')),
        ),
        GoRoute(
          path: '/categories',
          name: 'categories',
          builder: (_, _) => const Scaffold(body: Text('categories')),
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

  testWidgets('registra un ingreso end-to-end y lo persiste', (tester) async {
    await categoryRepo.add(name: 'Comida', iconName: 'Filled.Restaurant');

    await pumpPage(tester);

    // La categoría por defecto quedó preseleccionada (RN-006).
    expect(find.text('Comida'), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.tap(find.text('5'));
    await tester.tap(find.text('0'));
    await tester.pump();
    expect(find.text('150'), findsOneWidget); // display del monto

    await tester.tap(find.text('Guardar'));
    await tester.pump(); // arranca _save()
    await tester.pump(const Duration(milliseconds: 100)); // resuelve DB + estado guardado

    // El rediseño muestra el check "Guardado" en vez de un SnackBar.
    expect(find.text('Guardado'), findsOneWidget);

    final movements = await movementRepo.getAll();
    expect(movements.length, 1);
    expect(movements.single.amountCents, 15000);

    // Deja expirar el timer de la animación de guardado (≈950 ms).
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('el sheet de categoría cambia la categoría seleccionada',
      (tester) async {
    await categoryRepo.add(name: 'Comida', iconName: 'Filled.Restaurant');
    await categoryRepo.add(name: 'Transporte', iconName: 'Filled.DirectionsBus');

    await pumpPage(tester);
    // Por defecto se preselecciona la primera (orden alfabético): Comida.
    expect(find.text('Comida'), findsOneWidget);

    // Abre el sheet desde el chip de categoría.
    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();
    expect(find.text('Categoría'), findsOneWidget); // título del sheet
    expect(find.text('Nueva'), findsOneWidget); // tile de creación

    // Elige otra categoría.
    await tester.tap(find.text('Transporte'));
    await tester.pumpAndSettle();

    // El chip ahora muestra la nueva categoría y el sheet se cerró.
    expect(find.text('Transporte'), findsOneWidget);
    expect(find.text('Categoría'), findsNothing);
  });

  testWidgets('el sheet de fecha permite elegir Ayer', (tester) async {
    await categoryRepo.add(name: 'Comida', iconName: 'Filled.Restaurant');

    await pumpPage(tester);
    // El chip de fecha arranca en "Hoy".
    expect(find.text('Hoy'), findsOneWidget);

    await tester.tap(find.text('Hoy'));
    await tester.pumpAndSettle();
    expect(find.text('Fecha'), findsOneWidget); // título del sheet

    await tester.tap(find.text('Ayer'));
    await tester.pumpAndSettle();

    // El chip refleja la fecha elegida.
    expect(find.text('Ayer'), findsOneWidget);
    expect(find.text('Fecha'), findsNothing);
  });

  testWidgets('monto cero queda bloqueado (no persiste)', (tester) async {
    await categoryRepo.add(name: 'Comida', iconName: 'Filled.Restaurant');

    await pumpPage(tester);
    await tester.tap(find.text('Guardar'));
    // El rediseño sacude el monto (sin SnackBar); deja terminar la animación.
    await tester.pumpAndSettle();

    expect(find.text('0.00'), findsOneWidget); // el monto sigue en cero
    expect(await movementRepo.getAll(), isEmpty);
  });
}
