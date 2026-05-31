import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
      // Locale fijo es-MX (decisión F0): textos de los widgets de Material
      // (p. ej. showDatePicker) en español y consistentes con los formateadores
      // de moneda/fecha (R-06). La app es solo en español (discovery §1).
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
