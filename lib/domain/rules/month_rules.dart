/// Reglas relativas al mes mostrado en la lista (RN-004, RN-007). Sin UI.
library;

import '../models/movement.dart';
import '../models/transaction_type.dart';

/// Rango epoch **local** `[startMs, endMs)` que cubre el mes `month` de `year`.
///
/// Se calcula en zona local (no UTC) para evitar el desfase de `strftime`
/// `unixepoch` del origen (mitiga R-04). `DateTime(year, month + 1, 1)` maneja
/// correctamente el salto de año (diciembre → enero).
({int startMs, int endMs}) monthRangeMs(int year, int month) {
  final start = DateTime(year, month, 1);
  final end = DateTime(year, month + 1, 1);
  return (
    startMs: start.millisecondsSinceEpoch,
    endMs: end.millisecondsSinceEpoch,
  );
}

/// Verdadero si `(year, month)` es el mes en curso según `now` (default: ahora).
bool isCurrentMonth(int year, int month, {DateTime? now}) {
  final n = now ?? DateTime.now();
  return n.year == year && n.month == month;
}

/// Verdadero si se puede avanzar al mes siguiente: solo si el mes mostrado es
/// **anterior** al mes en curso (no se permite navegar a meses futuros, RN-004).
bool canGoToNextMonth(int year, int month, {DateTime? now}) {
  final n = now ?? DateTime.now();
  return year < n.year || (year == n.year && month < n.month);
}

/// Totales del mes por tipo (RN-007), en centavos.
class MonthTotals {
  const MonthTotals({required this.incomeCents, required this.expenseCents});

  final int incomeCents;
  final int expenseCents;

  int get balanceCents => incomeCents - expenseCents;
}

/// Suma por separado ingresos y egresos (RN-007). Opera sobre centavos `int`,
/// sin el riesgo de `amount.toDouble()` del origen (R-01).
MonthTotals computeMonthTotals(Iterable<Movement> movements) {
  var income = 0;
  var expense = 0;
  for (final m in movements) {
    switch (m.type) {
      case TransactionType.ingreso:
        income += m.amountCents;
      case TransactionType.egreso:
        expense += m.amountCents;
    }
  }
  return MonthTotals(incomeCents: income, expenseCents: expense);
}
