// Reglas de mes (RN-004, RN-007).

import 'package:cuantito/domain/models/category.dart';
import 'package:cuantito/domain/models/movement.dart';
import 'package:cuantito/domain/models/payment_method.dart';
import 'package:cuantito/domain/models/transaction_type.dart';
import 'package:cuantito/domain/rules/month_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('monthRangeMs (R-04, rango local)', () {
    test('cubre exactamente el mes en zona local', () {
      final r = monthRangeMs(2026, 5);
      expect(r.startMs, DateTime(2026, 5, 1).millisecondsSinceEpoch);
      expect(r.endMs, DateTime(2026, 6, 1).millisecondsSinceEpoch);
    });

    test('maneja el salto de año en diciembre', () {
      final r = monthRangeMs(2026, 12);
      expect(r.endMs, DateTime(2027, 1, 1).millisecondsSinceEpoch);
    });
  });

  group('navegación de meses (RN-004)', () {
    final now = DateTime(2026, 5, 15);

    test('isCurrentMonth', () {
      expect(isCurrentMonth(2026, 5, now: now), isTrue);
      expect(isCurrentMonth(2026, 4, now: now), isFalse);
    });

    test('no se puede avanzar al mes actual ni a meses futuros', () {
      expect(canGoToNextMonth(2026, 4, now: now), isTrue); // abril → mayo ok
      expect(canGoToNextMonth(2026, 5, now: now), isFalse); // ya es el actual
      expect(canGoToNextMonth(2026, 6, now: now), isFalse); // futuro
      expect(canGoToNextMonth(2025, 12, now: now), isTrue); // año anterior
    });
  });

  group('computeMonthTotals (RN-007)', () {
    Movement mov(TransactionType type, int cents) => Movement(
          id: 0,
          amountCents: cents,
          description: null,
          category: const Category(id: 1, name: 'X', iconName: 'i'),
          method: PaymentMethod.debito,
          type: type,
          dateTime: DateTime(2026, 5, 1),
        );

    test('suma ingresos y egresos por separado', () {
      final totals = computeMonthTotals([
        mov(TransactionType.ingreso, 10000),
        mov(TransactionType.ingreso, 5000),
        mov(TransactionType.egreso, 3000),
      ]);
      expect(totals.incomeCents, 15000);
      expect(totals.expenseCents, 3000);
      expect(totals.balanceCents, 12000);
    });

    test('lista vacía da ceros', () {
      final totals = computeMonthTotals(const []);
      expect(totals.incomeCents, 0);
      expect(totals.expenseCents, 0);
    });
  });
}
