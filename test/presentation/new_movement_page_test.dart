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
    await tester.pumpAndSettle();

    expect(find.text('Registrado con éxito'), findsOneWidget);

    final movements = await movementRepo.getAll();
    expect(movements.length, 1);
    expect(movements.single.amountCents, 15000);
  });

  testWidgets('monto cero queda bloqueado con mensaje', (tester) async {
    await categoryRepo.add(name: 'Comida', iconName: 'Filled.Restaurant');

    await pumpPage(tester);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('El monto no puede ser cero'), findsOneWidget);
    expect(await movementRepo.getAll(), isEmpty);
  });
}
