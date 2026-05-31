import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
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
/// Se expone como provider para que el `redirect` pueda leer el estado de
/// onboarding (RN-009): mientras esté pendiente, cualquier ruta redirige a
/// `/onboarding`; una vez completado, `/onboarding` redirige al inicio. El
/// estado se lee **en vivo** desde preferencias (`GetOnboardingStatus`), de modo
/// que tras `CompleteOnboarding` el guard ya no devuelve a Onboarding.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final showOnboarding = ref.read(getOnboardingStatusProvider)();
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (showOnboarding && !atOnboarding) return '/onboarding';
      if (!showOnboarding && atOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: AppRoute.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/',
        name: AppRoute.newMovement,
        builder: (context, state) => const NewMovementPage(),
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
});
