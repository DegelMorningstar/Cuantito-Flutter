// Widget tests de las pantallas de categorías (F5): listar/seleccionar y crear.

import 'package:cuantito/core/di/providers.dart';
import 'package:cuantito/data/local/app_database.dart' show AppDatabase;
import 'package:cuantito/data/repositories/category_repository_impl.dart';
import 'package:cuantito/domain/models/category.dart';
import 'package:cuantito/presentation/categories/new_category_page.dart';
import 'package:cuantito/presentation/categories/select_category_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late AppDatabase db;
  late CategoryRepositoryImpl repo;
  Object? popResult;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CategoryRepositoryImpl(db);
    popResult = null;
  });

  tearDown(() => db.close());

  /// Monta `target` tras una pantalla `/start` que la abre con `push`, dentro de
  /// un `ProviderScope` con la BD en memoria. Captura el valor devuelto al hacer
  /// pop en [popResult].
  Future<void> pumpScreen(
    WidgetTester tester, {
    required String path,
    required Widget target,
  }) async {
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async => popResult = await context.push(path),
                child: const Text('go'),
              ),
            ),
          ),
        ),
        GoRoute(path: path, builder: (context, state) => target),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  group('SelectCategoryPage', () {
    testWidgets('lista categorías y devuelve la elegida al tocarla',
        (tester) async {
      await repo.add(name: 'Comida', iconName: 'Filled.Restaurant');
      await repo.add(name: 'Transporte', iconName: 'Filled.DirectionsCar');

      await pumpScreen(
        tester,
        path: '/categories',
        target: const SelectCategoryPage(),
      );

      expect(find.text('Comida'), findsOneWidget);
      expect(find.text('Transporte'), findsOneWidget);

      await tester.tap(find.text('Transporte'));
      await tester.pumpAndSettle();

      expect(popResult, isA<Category>());
      expect((popResult! as Category).name, 'Transporte');
    });

    testWidgets('estado vacío seguro sin categorías (R-03)', (tester) async {
      await pumpScreen(
        tester,
        path: '/categories',
        target: const SelectCategoryPage(),
      );

      expect(find.textContaining('Aún no tienes categorías'), findsOneWidget);
    });
  });

  group('NewCategoryPage', () {
    testWidgets('nombre vacío muestra SnackBar y no guarda', (tester) async {
      await pumpScreen(
        tester,
        path: '/new',
        target: const NewCategoryPage(),
      );

      await tester.tap(find.text('Guardar'));
      await tester.pump(); // muestra el SnackBar

      expect(find.text('El nombre no puede estar vacío'), findsOneWidget);
      expect(await repo.getAll(), isEmpty);
    });

    testWidgets('nombre duplicado muestra SnackBar y limpia el campo',
        (tester) async {
      await repo.add(name: 'Comida', iconName: 'Filled.Restaurant');

      await pumpScreen(
        tester,
        path: '/new',
        target: const NewCategoryPage(),
      );

      await tester.enterText(find.byType(TextField), 'Comida');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Ya existe una categoría con ese nombre'),
          findsOneWidget);
      expect((await repo.getAll()).length, 1); // no se duplicó
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty);
    });

    testWidgets('guarda una categoría válida y persiste', (tester) async {
      await pumpScreen(
        tester,
        path: '/new',
        target: const NewCategoryPage(),
      );

      await tester.enterText(find.byType(TextField), 'Mascotas');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final all = await repo.getAll();
      expect(all.map((c) => c.name), contains('Mascotas'));
      expect(popResult, isTrue); // devolvió true al hacer pop
    });
  });
}
