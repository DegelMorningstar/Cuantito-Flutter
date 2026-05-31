// Verifica que los SVG del onboarding generados desde los VectorDrawables del
// origen (tool/generate_onboarding_svgs.dart) sean válidos y renderizables por
// flutter_svg. Guarda contra regresiones del conversor VD→SVG.

import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const assets = [
    'assets/onboarding/onboarding_one.svg',
    'assets/onboarding/onboarding_two.svg',
    'assets/onboarding/onboarding_three.svg',
  ];

  for (final path in assets) {
    test('$path es un SVG válido y renderizable', () async {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'falta $path; corre el generador');

      final svg = file.readAsStringSync();
      final info = await vg.loadPicture(SvgStringLoader(svg), null);
      addTearDown(info.picture.dispose);

      // Conserva el viewBox del VectorDrawable (dimensiones positivas).
      expect(info.size.width, greaterThan(0));
      expect(info.size.height, greaterThan(0));
    });
  }
}
