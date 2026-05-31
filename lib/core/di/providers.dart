import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/app_database.dart' show AppDatabase;
import '../../data/preferences/preferences_service.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/movement_repository_impl.dart';
import '../../data/repositories/preferences_repository_impl.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/movement_repository.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../../domain/usecases/category_usecases.dart';
import '../../domain/usecases/movement_usecases.dart';
import '../../domain/usecases/onboarding_usecases.dart';

// --------------------------------------------------------------- Infraestructura

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

// ----------------------------------------------------------------- Repositorios

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final movementRepositoryProvider = Provider<MovementRepository>(
  (ref) => MovementRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepositoryImpl(ref.watch(preferencesServiceProvider)),
);

// ------------------------------------------------------------------ Casos de uso

final addMovementProvider = Provider(
  (ref) => AddMovement(ref.watch(movementRepositoryProvider)),
);
final getAllMovementsProvider = Provider(
  (ref) => GetAllMovements(ref.watch(movementRepositoryProvider)),
);
final getMovementByIdProvider = Provider(
  (ref) => GetMovementById(ref.watch(movementRepositoryProvider)),
);
final getMovementsByMonthProvider = Provider(
  (ref) => GetMovementsByMonth(ref.watch(movementRepositoryProvider)),
);
final deleteMovementProvider = Provider(
  (ref) => DeleteMovement(ref.watch(movementRepositoryProvider)),
);

final addCategoryProvider = Provider(
  (ref) => AddCategory(ref.watch(categoryRepositoryProvider)),
);
final getAllCategoriesProvider = Provider(
  (ref) => GetAllCategories(ref.watch(categoryRepositoryProvider)),
);
final getCategoryByIdProvider = Provider(
  (ref) => GetCategoryById(ref.watch(categoryRepositoryProvider)),
);

final getOnboardingStatusProvider = Provider(
  (ref) => GetOnboardingStatus(ref.watch(preferencesRepositoryProvider)),
);
final completeOnboardingProvider = Provider(
  (ref) => CompleteOnboarding(ref.watch(preferencesRepositoryProvider)),
);

// ---------------------------------------------------------- Lectura (UI: F5–F9)

/// Lista de categorías (se refresca al invalidarse tras crear una). La UI de
/// categorías (F5) y NewMovement (F6) la consumen.
final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(getAllCategoriesProvider)(),
);

/// Estado del onboarding para el guard del router (F9).
final onboardingStatusProvider = Provider<bool>(
  (ref) => ref.watch(getOnboardingStatusProvider)(),
);
