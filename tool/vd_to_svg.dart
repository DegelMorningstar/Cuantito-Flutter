// Convierte un Android VectorDrawable (XML) a una cadena SVG.
//
// Soporta lo que usan las ilustraciones del onboarding del origen (unDraw):
// lista plana de <path> con android:pathData / fillColor / fillAlpha / fillType,
// y gradientes lineales/radiales embebidos vía <aapt:attr><gradient/>.
// No hay grupos, clip-paths ni strokes en esas ilustraciones.
//
// Es una utilidad de build (tool/), no forma parte de la app en runtime.

import 'package:xml/xml.dart';

const _androidNs = 'http://schemas.android.com/apk/res/android';

/// Convierte el contenido [vectorXml] de un VectorDrawable a una cadena SVG.
String vectorDrawableToSvg(String vectorXml) {
  final doc = XmlDocument.parse(vectorXml);
  final vector = doc.rootElement;

  final width = vector.getAttribute('viewportWidth', namespace: _androidNs)!;
  final height = vector.getAttribute('viewportHeight', namespace: _androidNs)!;

  final defs = StringBuffer();
  final body = StringBuffer();
  var gradientId = 0;

  for (final path in vector.findElements('path')) {
    final pathData = path.getAttribute('pathData', namespace: _androidNs);
    if (pathData == null) continue;

    final attrs = StringBuffer();

    final fillType = path.getAttribute('fillType', namespace: _androidNs);
    if (fillType != null && fillType.toLowerCase() == 'evenodd') {
      attrs.write(' fill-rule="evenodd"');
    }

    // El relleno puede ser un color plano o un <gradient> embebido en aapt:attr.
    final gradient = _embeddedGradient(path);
    if (gradient != null) {
      final id = 'grad${gradientId++}';
      defs.writeln(_gradientToSvg(gradient, id));
      attrs.write(' fill="url(#$id)"');
    } else {
      final fillColor =
          path.getAttribute('fillColor', namespace: _androidNs) ?? '#000000';
      final (color, opacity) = _parseColor(fillColor);
      attrs.write(' fill="$color"');
      if (opacity != null) attrs.write(' fill-opacity="$opacity"');
    }

    final fillAlpha = path.getAttribute('fillAlpha', namespace: _androidNs);
    if (fillAlpha != null) {
      // Se combina con la opacidad del color como un multiplicador global.
      attrs.write(' opacity="$fillAlpha"');
    }

    body.writeln('  <path d="$pathData"$attrs/>');
  }

  return '<svg xmlns="http://www.w3.org/2000/svg" '
      'viewBox="0 0 $width $height" width="$width" height="$height">\n'
      '${defs.isEmpty ? '' : '  <defs>\n$defs  </defs>\n'}'
      '$body'
      '</svg>\n';
}

/// Devuelve el `<gradient>` embebido en `<aapt:attr name="android:fillColor">`
/// de un `<path>`, o `null` si el relleno es un color plano.
XmlElement? _embeddedGradient(XmlElement path) {
  for (final attr in path.findElements('attr')) {
    if (attr.getAttribute('name') == 'android:fillColor') {
      final gradient = attr.findElements('gradient').firstOrNull;
      if (gradient != null) return gradient;
    }
  }
  return null;
}

String _gradientToSvg(XmlElement gradient, String id) {
  final type = gradient.getAttribute('type', namespace: _androidNs) ?? 'linear';
  final stops = StringBuffer();
  for (final item in gradient.findElements('item')) {
    final offset = item.getAttribute('offset', namespace: _androidNs) ?? '0';
    final colorRaw =
        item.getAttribute('color', namespace: _androidNs) ?? '#000000';
    final (color, opacity) = _parseColor(colorRaw);
    stops.write('      <stop offset="$offset" stop-color="$color"');
    if (opacity != null) stops.write(' stop-opacity="$opacity"');
    stops.writeln('/>');
  }

  String a(String name) => gradient.getAttribute(name, namespace: _androidNs) ?? '0';

  if (type == 'radial') {
    return '    <radialGradient id="$id" gradientUnits="userSpaceOnUse" '
        'cx="${a('centerX')}" cy="${a('centerY')}" r="${a('gradientRadius')}">\n'
        '$stops'
        '    </radialGradient>';
  }
  // linear (por defecto).
  return '    <linearGradient id="$id" gradientUnits="userSpaceOnUse" '
      'x1="${a('startX')}" y1="${a('startY')}" '
      'x2="${a('endX')}" y2="${a('endY')}">\n'
      '$stops'
      '    </linearGradient>';
}

/// Convierte un color Android (`#RRGGBB` o `#AARRGGBB`) a `(#RRGGBB, opacidad?)`.
(String, String?) _parseColor(String raw) {
  final hex = raw.replaceFirst('#', '');
  if (hex.length == 8) {
    final alpha = int.parse(hex.substring(0, 2), radix: 16);
    final rgb = '#${hex.substring(2)}';
    final opacity = (alpha / 255).toStringAsFixed(3);
    return (rgb, opacity);
  }
  return ('#$hex', null);
}
