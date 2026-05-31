import '../../domain/models/category.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/models/transaction_type.dart';
import '../categories/icon_catalog.dart';

/// Estado del formulario de NewMovement.
///
/// `amount` se mantiene como **String tecleado** (igual que el origen): se
/// construye dígito a dígito y solo se convierte a centavos al guardar.
class NewMovementState {
  const NewMovementState({
    required this.amount,
    required this.description,
    required this.method,
    required this.type,
    required this.dateTime,
    required this.category,
  });

  /// Estado inicial: monto `0.00`, egreso/débito, fecha = ahora y una categoría
  /// placeholder (id 0) que se reemplaza por la primera real al cargar (RN-006).
  factory NewMovementState.initial() => NewMovementState(
        amount: '0.00',
        description: '',
        method: PaymentMethod.debito,
        type: TransactionType.egreso,
        dateTime: DateTime.now(),
        category: const Category(
          id: 0,
          name: 'Selecciona una categoría...',
          iconName: kDefaultIconName,
        ),
      );

  final String amount;
  final String description;
  final PaymentMethod method;
  final TransactionType type;
  final DateTime dateTime;
  final Category category;

  /// Verdadero si aún no se ha elegido una categoría real (id 0 = placeholder).
  bool get hasCategory => category.id != 0;

  NewMovementState copyWith({
    String? amount,
    String? description,
    PaymentMethod? method,
    TransactionType? type,
    DateTime? dateTime,
    Category? category,
  }) =>
      NewMovementState(
        amount: amount ?? this.amount,
        description: description ?? this.description,
        method: method ?? this.method,
        type: type ?? this.type,
        dateTime: dateTime ?? this.dateTime,
        category: category ?? this.category,
      );
}
