/// Excepciones del dominio. Permiten a la presentación distinguir errores de
/// validación de negocio de fallos técnicos, y mostrar el mensaje adecuado.
library;

/// Base de los errores de validación de negocio.
sealed class DomainException implements Exception {
  const DomainException(this.message);
  final String message;

  @override
  String toString() => 'DomainException: $message';
}

/// El monto del movimiento no es válido (RN-001).
class InvalidAmountException extends DomainException {
  const InvalidAmountException()
      : super('El monto no puede ser cero');
}

/// El nombre de la categoría está vacío (RN-005).
class EmptyCategoryNameException extends DomainException {
  const EmptyCategoryNameException()
      : super('El nombre no puede estar vacío');
}

/// Ya existe una categoría con ese nombre (RN-005).
class CategoryAlreadyExistsException extends DomainException {
  const CategoryAlreadyExistsException()
      : super('Ya existe una categoría con ese nombre');
}
