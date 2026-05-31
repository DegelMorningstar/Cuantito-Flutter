// Smoke test del andamiaje (F1): con el onboarding ya completado, la app
// arranca en la pantalla de inicio (Nuevo movimiento) sin lanzar excepciones.
// El guard de onboarding (F9) lee preferencias, por eso se sobreescribe.

import 'package:cuantito/app/app.dart';
import 'package:cuantito/core/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('La app arranca en Nuevo movimiento', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_state': false});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CuantitoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nuevo movimiento'), findsOneWidget);
  });
}
