/// Parsers tolerantes para importar datos de la app Android legada (F3).
///
/// La BD Room guardaba el monto como `String` crudo (R-01) y los enums como su
/// `name`. Aquí se normalizan a los tipos del nuevo esquema Drift: centavos
/// (`int`) y texto canónico. Todo es tolerante a valores inesperados para no
/// perder/abortar la importación (mitiga R-01 y R-08).
library;

/// Convierte un monto en `String` (p. ej. `"1,234.50"`, `"1234.5"`, `"1.234,50"`)
/// a **centavos** (`int`). Devuelve `0` si no se puede interpretar.
///
/// Heurística de separadores:
/// - Si aparecen tanto `,` como `.`, el **último** es el separador decimal y el
///   otro se trata como separador de miles (se elimina).
/// - Si solo aparece uno y separa 1–2 dígitos finales, se trata como decimal;
///   en cualquier otro caso se trata como separador de miles.
int parseAmountToCents(String raw) {
  // Conservamos solo dígitos, separadores y signo.
  var s = raw.trim().replaceAll(RegExp(r'[^0-9,.\-]'), '');
  if (s.isEmpty || s == '-') return 0;

  final negative = s.startsWith('-');
  if (negative) s = s.substring(1);

  final hasComma = s.contains(',');
  final hasDot = s.contains('.');

  String decimalSep;
  if (hasComma && hasDot) {
    decimalSep = s.lastIndexOf(',') > s.lastIndexOf('.') ? ',' : '.';
  } else if (hasComma || hasDot) {
    final sep = hasComma ? ',' : '.';
    final decimals = s.length - s.lastIndexOf(sep) - 1;
    // Un único separador con 1–2 dígitos detrás ⇒ decimal; si no, miles.
    decimalSep = (s.split(sep).length == 2 && decimals >= 1 && decimals <= 2)
        ? sep
        : '';
  } else {
    decimalSep = '';
  }

  final String normalized;
  if (decimalSep.isEmpty) {
    // Sin parte decimal: todos los separadores son de miles.
    normalized = s.replaceAll(RegExp(r'[,.]'), '');
  } else {
    final thousandsSep = decimalSep == ',' ? '.' : ',';
    normalized = s.replaceAll(thousandsSep, '').replaceAll(decimalSep, '.');
  }

  final value = double.tryParse(normalized);
  if (value == null) return 0;

  final cents = (value * 100).round();
  return negative ? -cents : cents;
}

/// Tipos de movimiento válidos en el esquema nuevo.
const _validTypes = {'INGRESO', 'EGRESO'};

/// Métodos de pago válidos en el esquema nuevo.
const _validMethods = {'DEBITO', 'CREDITO'};

/// Normaliza el `type` legado al texto canónico. Default `EGRESO` si es
/// desconocido (mitiga R-08; en el origen `valueOf()` reventaba).
String normalizeType(String raw) {
  final up = raw.trim().toUpperCase();
  return _validTypes.contains(up) ? up : 'EGRESO';
}

/// Normaliza el `method` legado al texto canónico. Default `DEBITO` si es
/// desconocido (mitiga R-08).
String normalizeMethod(String raw) {
  final up = raw.trim().toUpperCase();
  return _validMethods.contains(up) ? up : 'DEBITO';
}
