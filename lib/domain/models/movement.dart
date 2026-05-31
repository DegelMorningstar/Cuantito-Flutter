import 'category.dart';
import 'payment_method.dart';
import 'transaction_type.dart';

/// Movimiento (ingreso/egreso). Modelo de dominio **puro** (R-07).
///
/// - `amountCents`: monto en **centavos** (`int`, decisión F0; elimina R-01).
/// - `dateTime`: instante del movimiento (en mapeo se persiste como epoch ms).
/// - `category`: categoría asociada (join resuelto en el repositorio).
class Movement {
  const Movement({
    required this.id,
    required this.amountCents,
    required this.description,
    required this.category,
    required this.method,
    required this.type,
    required this.dateTime,
  });

  /// `0` indica un movimiento aún no persistido.
  final int id;
  final int amountCents;
  final String? description;
  final Category category;
  final PaymentMethod method;
  final TransactionType type;
  final DateTime dateTime;

  Movement copyWith({
    int? id,
    int? amountCents,
    String? description,
    Category? category,
    PaymentMethod? method,
    TransactionType? type,
    DateTime? dateTime,
  }) =>
      Movement(
        id: id ?? this.id,
        amountCents: amountCents ?? this.amountCents,
        description: description ?? this.description,
        category: category ?? this.category,
        method: method ?? this.method,
        type: type ?? this.type,
        dateTime: dateTime ?? this.dateTime,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movement &&
          other.id == id &&
          other.amountCents == amountCents &&
          other.description == description &&
          other.category == category &&
          other.method == method &&
          other.type == type &&
          other.dateTime == dateTime;

  @override
  int get hashCode => Object.hash(
        id,
        amountCents,
        description,
        category,
        method,
        type,
        dateTime,
      );

  @override
  String toString() =>
      'Movement(id: $id, amountCents: $amountCents, type: ${type.name}, '
      'method: ${method.name}, category: ${category.name})';
}
