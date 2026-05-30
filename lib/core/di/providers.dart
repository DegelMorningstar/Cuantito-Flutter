import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/app_database.dart';
import '../../data/preferences/preferences_service.dart';

/// Instancia de [SharedPreferences].
///
/// Se sobreescribe en `main()` con el valor real tras
/// `SharedPreferences.getInstance()` (patrón de override de Riverpod).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider debe sobreescribirse en main()',
  ),
);

/// Servicio de preferencias (bandera de onboarding).
final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) => PreferencesService(ref.watch(sharedPreferencesProvider)),
);

/// Base de datos Drift (singleton durante la vida de la app).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
