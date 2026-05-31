import 'package:drift/drift.dart';

import '../../domain/models/category.dart';
import '../../domain/models/movement.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/models/transaction_type.dart';
import '../local/app_database.dart' as db;

/// Conversión entre la fila Drift `Movement` y el modelo de dominio [Movement].
extension MovementRowMapper on db.Movement {
  /// Requiere la [category] ya resuelta (el join lo hace el repositorio).
  Movement toDomain(Category category) => Movement(
        id: id,
        amountCents: amountCents,
        description: description,
        category: category,
        method: PaymentMethod.fromStorage(method),
        type: TransactionType.fromStorage(type),
        dateTime: DateTime.fromMillisecondsSinceEpoch(transactionDate),
      );
}

/// Conversión del modelo de dominio a un companion para insertar en Drift.
extension MovementToCompanion on Movement {
  db.MovementsCompanion toCompanion() => db.MovementsCompanion.insert(
        amountCents: amountCents,
        categoryId: category.id,
        method: method.storageName,
        type: type.storageName,
        transactionDate: dateTime.millisecondsSinceEpoch,
        description:
            description == null ? const Value.absent() : Value(description),
      );
}
