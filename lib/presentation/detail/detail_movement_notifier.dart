import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../movements/movements_list_notifier.dart';
import 'detail_movement_state.dart';

/// Lógica del detalle de un movimiento (porta `DetailMovementViewModel`).
///
/// Familia parametrizada por el **id** del movimiento: `build` lo carga con su
/// categoría vía `GetMovementById` (puede devolver `null` → estado defensivo).
/// Es **autoDispose** para no retener detalles ya cerrados.
class DetailMovementNotifier extends AsyncNotifier<DetailMovementState> {
  DetailMovementNotifier(this.movementId);

  /// Id del movimiento a mostrar (argumento de la familia).
  final int movementId;

  @override
  Future<DetailMovementState> build() async {
    final movement = await ref.read(getMovementByIdProvider)(movementId);
    return DetailMovementState(movement: movement);
  }

  /// Elimina el movimiento e invalida la lista mensual para que desaparezca de
  /// ella (y de sus totales) al volver. Marca `isDeleted` para que la pantalla
  /// reaccione y regrese atrás.
  Future<void> delete() async {
    final movement = state.value?.movement;
    if (movement == null) return;

    await ref.read(deleteMovementProvider)(movement.id);
    ref.invalidate(movementsListProvider);
    state = AsyncData(
      DetailMovementState(movement: movement, isDeleted: true),
    );
  }
}

final detailMovementProvider = AsyncNotifierProvider.autoDispose
    .family<DetailMovementNotifier, DetailMovementState, int>(
  DetailMovementNotifier.new,
);
