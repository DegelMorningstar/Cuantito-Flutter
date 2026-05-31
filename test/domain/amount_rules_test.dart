// Reglas de monto (RN-001, RN-002).

import 'package:cuantito/domain/rules/amount_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidAmountInput (RN-001)', () {
    test('rechaza los casos inválidos del origen', () {
      for (final raw in ['', '0', '0.', '0.00', '0,00']) {
        expect(isValidAmountInput(raw), isFalse, reason: 'raw="$raw"');
      }
    });

    test('acepta montos positivos', () {
      for (final raw in ['0.01', '1', '1234.50', '1,234.50']) {
        expect(isValidAmountInput(raw), isTrue, reason: 'raw="$raw"');
      }
    });
  });

  group('isValidAmountCents (RN-001)', () {
    test('solo positivos son válidos', () {
      expect(isValidAmountCents(1), isTrue);
      expect(isValidAmountCents(0), isFalse);
      expect(isValidAmountCents(-5), isFalse);
    });
  });
}
