import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Raíz de la aplicación Cuantito.
///
/// Configura tema (Material 3), enrutador (go_router, con guard de onboarding)
/// y modo de tema. La localización (intl) y el modo de tema persistido se
/// conectan en fases posteriores (ver `ai/PLAN_IMPLEMENTACION_FLUTTER.md`, F10 /
/// Settings).
class CuantitoApp extends ConsumerWidget {
  const CuantitoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Cuantito',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
