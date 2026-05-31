import '../exceptions.dart';
import '../models/movement.dart';
import '../repositories/movement_repository.dart';
import '../rules/amount_rules.dart';

/// Registrar un movimiento. Valida el monto (RN-001) antes de persistir.
class AddMovement {
  const AddMovement(this._repository);
  final MovementRepository _repository;

  /// Lanza [InvalidAmountException] si el monto no es positivo.
  Future<int> call(Movement movement) {
    if (!isValidAmountCents(movement.amountCents)) {
      throw const InvalidAmountException();
    }
    return _repository.add(movement);
  }
}

/// Todos los movimientos (fecha desc).
class GetAllMovements {
  const GetAllMovements(this._repository);
  final MovementRepository _repository;

  Future<List<Movement>> call() => _repository.getAll();
}

/// Un movimiento por id (con su categoría) o `null`.
class GetMovementById {
  const GetMovementById(this._repository);
  final MovementRepository _repository;

  Future<Movement?> call(int id) => _repository.getById(id);
}

/// Movimientos del mes indicado (RN-004 / RN-007).
class GetMovementsByMonth {
  const GetMovementsByMonth(this._repository);
  final MovementRepository _repository;

  Future<List<Movement>> call(int year, int month) =>
      _repository.getByMonth(year, month);
}

/// Eliminar un movimiento.
class DeleteMovement {
  const DeleteMovement(this._repository);
  final MovementRepository _repository;

  Future<int> call(int id) => _repository.delete(id);
}
