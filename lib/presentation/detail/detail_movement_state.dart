import '../../domain/models/movement.dart';

/// Estado de la pantalla de detalle (porta `DetailMovementState` del origen).
///
/// - `movement`: el movimiento cargado por id (con su categoría), o `null` si no
///   existe (estado defensivo, mejora la UX no resuelta del origen).
/// - `isDeleted`: pasa a `true` tras eliminar; la pantalla reacciona y vuelve
///   atrás.
class DetailMovementState {
  const DetailMovementState({this.movement, this.isDeleted = false});

  final Movement? movement;
  final bool isDeleted;

  DetailMovementState copyWith({Movement? movement, bool? isDeleted}) =>
      DetailMovementState(
        movement: movement ?? this.movement,
        isDeleted: isDeleted ?? this.isDeleted,
      );
}
