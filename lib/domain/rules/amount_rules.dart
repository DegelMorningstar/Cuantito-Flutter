/// Reglas de monto del dominio (RN-001, RN-002). Sin dependencias de UI.
library;

/// Convierte un monto en `String` (p. ej. `"1,234.50"`, `"1234.5"`, `"1.234,50"`)
/// a **centavos** (`int`). Devuelve `0` si no se puede interpretar.
///
/// Heurística de separadores:
/// - Si aparecen tanto `,` como `.`, el **último** es el separador decimal y el
///   otro se trata como separador de miles (se elimina).
/// - Si solo aparece uno y separa 1–2 dígitos finales, se trata como decimal;
///   en cualquier otro caso se trata como separador de miles.
///
/// Es la fuente única de verdad usada tanto por la entrada del teclado (F6)
/// como por la importación legada (F3), eliminando R-01.
int parseAmountToCents(String raw) {
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
    decimalSep = (s.split(sep).length == 2 && decimals >= 1 && decimals <= 2)
        ? sep
        : '';
  } else {
    decimalSep = '';
  }

  final String normalized;
  if (decimalSep.isEmpty) {
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

/// Verdadero si el monto **tecleado** es válido para guardar (RN-001): rechaza
/// `""`, `"0"`, `"0."`, `"0.00"` y cualquier cosa que no represente un valor
/// positivo. Equivalente a `isValidAmount()` del origen.
bool isValidAmountInput(String raw) => parseAmountToCents(raw) > 0;

/// Verdadero si un monto ya normalizado (centavos) es válido para guardar.
bool isValidAmountCents(int cents) => cents > 0;
