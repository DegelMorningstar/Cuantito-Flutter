/// Parsers tolerantes para importar datos de la app Android legada (F3).
///
/// El monto y los enums se normalizan reutilizando las reglas y enums del
/// **dominio** (fuente única de verdad), de modo que la importación y la app
/// usan exactamente la misma lógica (mitiga R-01 y R-08).
library;

import '../../domain/models/payment_method.dart';
import '../../domain/models/transaction_type.dart';

export '../../domain/rules/amount_rules.dart' show parseAmountToCents;

/// Normaliza el `type` legado al texto canónico persistido. Default `EGRESO`
/// ante valores desconocidos (R-08).
String normalizeType(String raw) => TransactionType.fromStorage(raw).storageName;

/// Normaliza el `method` legado al texto canónico persistido. Default `DEBITO`
/// ante valores desconocidos (R-08).
String normalizeMethod(String raw) => PaymentMethod.fromStorage(raw).storageName;
