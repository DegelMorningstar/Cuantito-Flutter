import '../models/movement.dart';

/// Contrato de acceso a movimientos. La implementación vive en `data/`.
abstract interface class MovementRepository {
  /// Inserta el movimiento y devuelve su `id` generado.
  Future<int> add(Movement movement);

  /// Movimiento por id (con su categoría) o `null` si no existe.
  Future<Movement?> getById(int id);

  /// Todos los movimientos, ordenados por fecha descendente.
  Future<List<Movement>> getAll();

  /// Movimientos del mes indicado (rango local), por fecha descendente (RN-004).
  Future<List<Movement>> getByMonth(int year, int month);

  /// Elimina el movimiento; devuelve cuántas filas se borraron.
  Future<int> delete(int id);
}
