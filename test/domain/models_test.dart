// Modelos y enums de dominio (RN-003, R-08).

import 'package:cuantito/domain/models/category.dart';
import 'package:cuantito/domain/models/payment_method.dart';
import 'package:cuantito/domain/models/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionType (RN-003 / R-08)', () {
    test('fromStorage tolerante con default EGRESO', () {
      expect(TransactionType.fromStorage('INGRESO'), TransactionType.ingreso);
      expect(TransactionType.fromStorage(' egreso '), TransactionType.egreso);
      expect(TransactionType.fromStorage('???'), TransactionType.egreso);
    });

    test('storageName es estable para persistencia', () {
      expect(TransactionType.ingreso.storageName, 'INGRESO');
      expect(TransactionType.egreso.storageName, 'EGRESO');
    });
  });

  group('PaymentMethod (RN-003 / R-08)', () {
    test('fromStorage tolerante con default DEBITO', () {
      expect(PaymentMethod.fromStorage('CREDITO'), PaymentMethod.credito);
      expect(PaymentMethod.fromStorage('paypal'), PaymentMethod.debito);
    });

    test('storageName es estable para persistencia', () {
      expect(PaymentMethod.debito.storageName, 'DEBITO');
      expect(PaymentMethod.credito.storageName, 'CREDITO');
    });
  });

  group('Category (igualdad de valor)', () {
    test('== y copyWith', () {
      const a = Category(id: 1, name: 'Comida', iconName: 'cart');
      expect(a, const Category(id: 1, name: 'Comida', iconName: 'cart'));
      expect(a.copyWith(name: 'Otra'),
          const Category(id: 1, name: 'Otra', iconName: 'cart'));
    });
  });
}
