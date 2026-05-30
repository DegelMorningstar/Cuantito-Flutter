// Smoke test del andamiaje (F1): la app arranca en la pantalla de inicio
// (Nuevo movimiento) sin lanzar excepciones.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuantito/app/app.dart';

void main() {
  testWidgets('La app arranca en Nuevo movimiento', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CuantitoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo movimiento'), findsOneWidget);
  });
}
