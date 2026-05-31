// Widget test del detalle (F8): render del movimiento, estado defensivo cuando
// no existe, y borrado con confirmación que vuelve atrás.

import 'package:cuantito/app/theme/app_theme.dart';
import 'package:cuantito/core/di/providers.dart';
import 'package:cuantito/data/local/app_database.dart' show AppDatabase;
import 'package:cuantito/data/repositories/category_repository_impl.dart';
import 'package:cuantito/data/repositories/movement_repository_impl.dart';
import 'package:cuantito/domain/models/category.dart';
import 'package:cuantito/domain/models/movement.dart';
import 'package:cuantito/domain/models/payment_method.dart';
import 'package:cuantito/domain/models/transaction_type.dart';
import 'package:cuantito/presentation/detail/detail_movement_page.dart';
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

  Future<int> addMovement({
    required Category category,
    String? description,
    TransactionType type = TransactionType.egreso,
  }) async {
    return movementRepo.add(
      Movement(
        id: 0,
        amountCents: 15000,
        description: description,
        category: category,
        method: PaymentMethod.credito,
        type: type,
        dateTime: DateTime(2026, 5, 5),
      ),
    );
  }

  Future<void> pumpPage(WidgetTester tester, int movementId) async {
    final router = GoRouter(
      initialLocation: '/movements',
      routes: [
        GoRoute(
          path: '/movements',
          builder: (_, _) =>
              Scaffold(body: Center(child: Text('lista', key: const Key('lista')))),
          routes: [
            GoRoute(
              path: 'detail/:id',
              builder: (_, state) => DetailMovementPage(
                movementId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ],
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
    // Navega al detalle (deja la lista en el stack para verificar el pop).
    router.go('/movements/detail/$movementId');
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el detalle del movimiento', (tester) async {
    final category = await seedCategory();
    final id = await addMovement(category: category, description: 'Cena');

    await pumpPage(tester, id);

    expect(find.text('Detalle del Movimiento'), findsOneWidget);
    expect(find.text('Cena'), findsOneWidget);
    expect(find.text(r'$150.00'), findsOneWidget);
    expect(find.text('Egreso'), findsOneWidget);
    // Con descripción se muestra también la fila de categoría.
    expect(find.text('Categoría:'), findsOneWidget);
    expect(find.text('Crédito'), findsOneWidget);
    expect(find.text('5 de mayo, 2026'), findsOneWidget);
  });

  testWidgets('sin descripción usa el nombre de la categoría y oculta la fila',
      (tester) async {
    final category = await seedCategory();
    final id = await addMovement(category: category);

    await pumpPage(tester, id);

    // El título del detalle es el nombre de la categoría.
    expect(find.text('Comida'), findsOneWidget);
    // Sin descripción no se muestra la fila "Categoría:".
    expect(find.text('Categoría:'), findsNothing);
  });

  testWidgets('estado defensivo cuando el movimiento no existe', (tester) async {
    await seedCategory();
    await pumpPage(tester, 999);

    expect(find.text('No se encontró el movimiento'), findsOneWidget);
  });

  testWidgets('eliminar pide confirmación, borra y vuelve atrás',
      (tester) async {
    final category = await seedCategory();
    final id = await addMovement(category: category, description: 'Cena');

    await pumpPage(tester, id);
    expect(find.text('Cena'), findsOneWidget);

    await tester.tap(find.text('Eliminar Registro'));
    await tester.pumpAndSettle();

    // Aparece el diálogo de confirmación.
    expect(find.text('¿Seguro que deseas eliminar este registro?'),
        findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    // Volvió a la lista y el movimiento se borró de la BD.
    expect(find.byKey(const Key('lista')), findsOneWidget);
    expect(await movementRepo.getById(id), isNull);
  });

  testWidgets('cancelar la confirmación no borra el movimiento', (tester) async {
    final category = await seedCategory();
    final id = await addMovement(category: category, description: 'Cena');

    await pumpPage(tester, id);

    await tester.tap(find.text('Eliminar Registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    // Sigue en el detalle y el movimiento persiste.
    expect(find.text('Cena'), findsOneWidget);
    expect(await movementRepo.getById(id), isNotNull);
  });
}
