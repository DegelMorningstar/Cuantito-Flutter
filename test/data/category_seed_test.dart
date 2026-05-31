// Seed de categorías iniciales (decisión F0; mitiga R-03).

import 'package:cuantito/data/local/app_database.dart' show AppDatabase;
import 'package:cuantito/data/repositories/category_repository_impl.dart';
import 'package:cuantito/data/seed/category_seed.dart';
import 'package:cuantito/presentation/categories/icon_catalog.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CategoryRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CategoryRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('siembra las categorías iniciales cuando la tabla está vacía', () async {
    final seeded = await seedCategoriesIfEmpty(repo);

    expect(seeded, isTrue);
    final names = (await repo.getAll()).map((c) => c.name).toSet();
    expect(names, containsAll(['Comida', 'Transporte', 'Salario']));
    expect((await repo.getAll()).length, kInitialCategories.length);
  });

  test('los iconos sembrados existen en el catálogo (resuelven sin fallback)',
      () async {
    for (final c in kInitialCategories) {
      expect(iconForName(c.iconName), isNot(kDefaultIcon),
          reason: c.iconName);
    }
  });

  test('no vuelve a sembrar si ya hay categorías', () async {
    await repo.add(name: 'Existente', iconName: 'Filled.Home');

    final seeded = await seedCategoriesIfEmpty(repo);

    expect(seeded, isFalse);
    expect((await repo.getAll()).length, 1);
  });
}
