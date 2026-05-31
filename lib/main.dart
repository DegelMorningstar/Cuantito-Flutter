import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/di/providers.dart';
import 'data/local/app_database.dart';
import 'data/migration/legacy_migration_service.dart';
import 'data/preferences/preferences_service.dart';
import 'data/repositories/category_repository_impl.dart';
import 'data/seed/category_seed.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(prefs);
  final database = AppDatabase();

  // Importa, una sola vez, los datos de la app Android previa (Room) si existen
  // (F3). Se ejecuta antes de runApp para que las pantallas ya vean los datos.
  await LegacyMigrationService(
    db: database,
    prefs: preferencesService,
  ).migrateIfNeeded();

  // Seed de categorías iniciales si la tabla quedó vacía (decisión F0; mitiga
  // R-03). Tras la migración, para no duplicar datos ya importados.
  await seedCategoriesIfEmpty(CategoryRepositoryImpl(database));

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const CuantitoApp(),
    ),
  );
}
