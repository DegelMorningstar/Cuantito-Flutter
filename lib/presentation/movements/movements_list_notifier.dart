import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/rules/month_rules.dart';
import 'movements_list_state.dart';

/// Lógica de la lista mensual (porta `MovementsListViewModel`).
///
/// Arranca en el mes en curso y carga sus movimientos. La navegación entre
/// meses recarga la consulta; el toggle del resumen no toca la BD.
///
/// Es **autoDispose**: cada vez que la pantalla se monta se reconstruye el
/// estado, por lo que los movimientos recién creados en NewMovement aparecen al
/// volver a abrir la lista (sin caché obsoleta).
class MovementsListNotifier extends AsyncNotifier<MovementsListState> {
  late int _year;
  late int _month;
  var _showExpenses = true;

  @override
  Future<MovementsListState> build() {
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    return _load();
  }

  Future<MovementsListState> _load() async {
    final movements = await ref.read(getMovementsByMonthProvider)(_year, _month);
    return MovementsListState(
      year: _year,
      month: _month,
      movements: movements,
      showExpenses: _showExpenses,
    );
  }

  /// Retrocede un mes y recarga. `DateTime(year, month - 1)` maneja el salto de
  /// año (enero → diciembre del año anterior).
  Future<void> goToPreviousMonth() async {
    final prev = DateTime(_year, _month - 1);
    _year = prev.year;
    _month = prev.month;
    await _reload();
  }

  /// Avanza un mes, salvo que ya estemos en el mes en curso (RN-004).
  Future<void> goToNextMonth() async {
    if (!canGoToNextMonth(_year, _month)) return;
    final next = DateTime(_year, _month + 1);
    _year = next.year;
    _month = next.month;
    await _reload();
  }

  /// Alterna el resumen entre egresos e ingresos (RN-007). No recarga la BD.
  void toggleSummary() {
    _showExpenses = !_showExpenses;
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(showExpenses: _showExpenses));
    }
  }

  /// Recarga conservando el estado anterior mientras llega el nuevo (evita el
  /// parpadeo a spinner al cambiar de mes).
  Future<void> _reload() async {
    state = await AsyncValue.guard(_load);
  }
}

final movementsListProvider =
    AsyncNotifierProvider.autoDispose<MovementsListNotifier, MovementsListState>(
  MovementsListNotifier.new,
);
