// Generador one-shot: convierte los VectorDrawables del onboarding (copiados del
// origen Android en tool/onboarding_vd/) a SVG en assets/onboarding/.
//
// Ejecutar desde la raíz del proyecto:
//   dart run tool/generate_onboarding_svgs.dart
//
// Es una utilidad de build; no forma parte de la app en runtime.

import 'dart:io';

import 'vd_to_svg.dart';

const _names = ['onboarding_one', 'onboarding_two', 'onboarding_three'];

void main() {
  final srcDir = Directory('tool/onboarding_vd');
  final outDir = Directory('assets/onboarding')..createSync(recursive: true);

  for (final name in _names) {
    final src = File('${srcDir.path}/$name.xml');
    if (!src.existsSync()) {
      stderr.writeln('No se encontró ${src.path}; se omite.');
      continue;
    }
    final svg = vectorDrawableToSvg(src.readAsStringSync());
    final out = File('${outDir.path}/$name.svg')..writeAsStringSync(svg);
    stdout.writeln('Generado ${out.path} (${svg.length} bytes)');
  }
}
