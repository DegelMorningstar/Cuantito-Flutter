// Widget test del onboarding (F9): el guard del router muestra el onboarding en
// la primera ejecución, los slides avanzan, y al finalizar/saltar se completa
// (RN-009) y se navega a Nuevo movimiento.

import 'package:cuantito/app/app.dart';
import 'package:cuantito/core/di/providers.dart';
import 'package:cuantito/data/local/app_database.dart' show AppDatabase;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Monta la app real (con su guard de onboarding) con preferencias simuladas.
  Future<SharedPreferences> pumpApp(
    WidgetTester tester, {
    required bool onboardingDone,
  }) async {
    SharedPreferences.setMockInitialValues(
      onboardingDone ? {'onboarding_state': false} : {},
    );
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const CuantitoApp(),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
  }

  testWidgets('primera ejecución: el guard muestra el onboarding',
      (tester) async {
    await pumpApp(tester, onboardingDone: false);

    expect(find.text('Registro de gastos y de ingresos'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
    expect(find.text('Saltar'), findsOneWidget);
    // No estamos aún en la pantalla de inicio.
    expect(find.text('Nuevo movimiento'), findsNothing);
  });

  testWidgets('ejecuciones posteriores van directo a Nuevo movimiento',
      (tester) async {
    await pumpApp(tester, onboardingDone: true);

    expect(find.text('Nuevo movimiento'), findsOneWidget);
    expect(find.text('Registro de gastos y de ingresos'), findsNothing);
  });

  testWidgets('Siguiente avanza hasta el último slide (Finalizar)',
      (tester) async {
    await pumpApp(tester, onboardingDone: false);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Mis gastos'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Categorías'), findsOneWidget);
    // En el último slide cambia el botón y se oculta "Saltar".
    expect(find.text('Finalizar'), findsOneWidget);
    expect(find.text('Saltar'), findsNothing);
  });

  testWidgets('Finalizar completa el onboarding y navega a Nuevo movimiento',
      (tester) async {
    final prefs = await pumpApp(tester, onboardingDone: false);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo movimiento'), findsOneWidget);
    expect(prefs.getBool('onboarding_state'), isFalse);
  });

  testWidgets('Saltar completa el onboarding y navega a Nuevo movimiento',
      (tester) async {
    final prefs = await pumpApp(tester, onboardingDone: false);

    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo movimiento'), findsOneWidget);
    expect(prefs.getBool('onboarding_state'), isFalse);
  });
}
