import '../../domain/models/movement.dart';
import '../../domain/rules/month_rules.dart';
import '../../core/format/formatters.dart';

/// Estado de la pantalla de lista mensual (porta `MovementsListState` del
/// origen). Mantiene el mes mostrado (`year`/`month`), los movimientos de ese
/// mes y si el resumen muestra egresos o ingresos.
class MovementsListState {
  const MovementsListState({
    required this.year,
    required this.month,
    required this.movements,
    required this.showExpenses,
  });

  /// Año mostrado.
  final int year;

  /// Mes mostrado (1–12).
  final int month;

  /// Movimientos del mes (orden fecha desc, ya resuelto por la consulta).
  final List<Movement> movements;

  /// `true` → el resumen muestra egresos; `false` → ingresos (RN-007).
  final bool showExpenses;

  /// Totales del mes por tipo (RN-007), en centavos.
  MonthTotals get totals => computeMonthTotals(movements);

  /// Total mostrado en el resumen según [showExpenses].
  int get summaryCents =>
      showExpenses ? totals.expenseCents : totals.incomeCents;

  /// Si se puede avanzar al mes siguiente (no se permiten meses futuros, RN-004).
  bool get canGoToNext => canGoToNextMonth(year, month);

  /// Etiqueta del selector, p. ej. `"Mayo 2026"`.
  String get monthLabel => '${monthName(month)} $year';

  MovementsListState copyWith({
    int? year,
    int? month,
    List<Movement>? movements,
    bool? showExpenses,
  }) =>
      MovementsListState(
        year: year ?? this.year,
        month: month ?? this.month,
        movements: movements ?? this.movements,
        showExpenses: showExpenses ?? this.showExpenses,
      );
}
