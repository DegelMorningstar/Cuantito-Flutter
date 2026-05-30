import 'package:go_router/go_router.dart';

import '../../presentation/categories/new_category_page.dart';
import '../../presentation/categories/select_category_page.dart';
import '../../presentation/detail/detail_movement_page.dart';
import '../../presentation/movements/movements_list_page.dart';
import '../../presentation/newmovement/new_movement_page.dart';
import '../../presentation/onboarding/onboarding_page.dart';

/// Nombres de ruta (para navegación por nombre con go_router).
abstract final class AppRoute {
  const AppRoute._();

  static const onboarding = 'onboarding';
  static const newMovement = 'newMovement';
  static const movements = 'movements';
  static const detail = 'detail';
  static const categories = 'categories';
  static const newCategory = 'newCategory';
}

/// Enrutador principal de la app (las 6 pantallas del discovery §7).
///
/// Por ahora arranca en `NewMovement` (start destination post-onboarding).
/// TODO(F9): añadir `redirect` que muestre Onboarding cuando
/// `GetOnboardingStatus` sea verdadero.
final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/onboarding',
      name: AppRoute.onboarding,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/',
      name: AppRoute.newMovement,
      builder: (context, state) {
        final categoryId = int.tryParse(
          state.uri.queryParameters['categoryId'] ?? '',
        );
        return NewMovementPage(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/movements',
      name: AppRoute.movements,
      builder: (context, state) => const MovementsListPage(),
    ),
    GoRoute(
      path: '/movements/detail/:id',
      name: AppRoute.detail,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return DetailMovementPage(movementId: id);
      },
    ),
    GoRoute(
      path: '/categories',
      name: AppRoute.categories,
      builder: (context, state) {
        final selectedCategoryId = int.tryParse(
          state.uri.queryParameters['selectedCategoryId'] ?? '',
        );
        return SelectCategoryPage(selectedCategoryId: selectedCategoryId);
      },
    ),
    GoRoute(
      path: '/categories/new',
      name: AppRoute.newCategory,
      builder: (context, state) => const NewCategoryPage(),
    ),
  ],
);
