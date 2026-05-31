// Tests unitarios de los parsers tolerantes de la migración legada (F3).

import 'package:cuantito/data/migration/legacy_parsers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAmountToCents', () {
    test('decimal con punto (formato del teclado original)', () {
      expect(parseAmountToCents('1234.50'), 123450);
      expect(parseAmountToCents('0.00'), 0);
      expect(parseAmountToCents('99.9'), 9990);
    });

    test('entero sin decimales', () {
      expect(parseAmountToCents('150'), 15000);
    });

    test('miles con coma + decimal con punto', () {
      expect(parseAmountToCents('1,234.50'), 123450);
      expect(parseAmountToCents('1,000,000.00'), 100000000);
    });

    test('formato europeo: miles con punto + decimal con coma', () {
      expect(parseAmountToCents('1.234,50'), 123450);
    });

    test('coma como único separador decimal', () {
      expect(parseAmountToCents('99,9'), 9990);
      expect(parseAmountToCents('12,34'), 1234);
    });

    test('símbolos y espacios se ignoran', () {
      expect(parseAmountToCents(r'$ 1,234.50'), 123450);
      expect(parseAmountToCents('  150  '), 15000);
    });

    test('negativo se conserva', () {
      expect(parseAmountToCents('-50.00'), -5000);
    });

    test('valores no interpretables devuelven 0 (no crashea, R-01)', () {
      expect(parseAmountToCents(''), 0);
      expect(parseAmountToCents('abc'), 0);
      expect(parseAmountToCents('-'), 0);
    });
  });

  group('normalizeType / normalizeMethod (R-08)', () {
    test('valores válidos se conservan (case-insensitive)', () {
      expect(normalizeType('INGRESO'), 'INGRESO');
      expect(normalizeType('egreso'), 'EGRESO');
      expect(normalizeMethod('DEBITO'), 'DEBITO');
      expect(normalizeMethod(' credito '), 'CREDITO');
    });

    test('valores desconocidos caen al default', () {
      expect(normalizeType('CUALQUIERA'), 'EGRESO');
      expect(normalizeMethod('PAYPAL'), 'DEBITO');
      expect(normalizeType(''), 'EGRESO');
    });
  });
}
