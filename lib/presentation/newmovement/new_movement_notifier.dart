import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/models/category.dart';
import '../../domain/models/movement.dart';
import '../../domain/rules/amount_rules.dart';
import 'new_movement_state.dart';

/// Resultado de intentar guardar un movimiento.
enum SaveResult { success, invalidAmount, noCategory }

/// Lógica del formulario de NewMovement (porta `NewMovementViewModel`).
class NewMovementNotifier extends Notifier<NewMovementState> {
  @override
  NewMovementState build() => NewMovementState.initial();

  /// Teclear un dígito o el punto decimal (RN-002):
  /// - `.` solo si aún no hay punto.
  /// - un dígito reemplaza el `0.00` inicial; si no, se concatena.
  void onKey(String input) {
    final current = state.amount;
    final String next;
    if (input == '.') {
      next = current.contains('.') ? current : '$current.';
    } else {
      next = current == '0.00' ? input : '$current$input';
    }
    state = state.copyWith(amount: next);
  }

  /// Backspace: borra el último carácter; al quedar 1 carácter vuelve a `0.00`.
  void onBackspace() {
    final current = state.amount;
    final next = (current.length > 1 && current != '0.00')
        ? current.substring(0, current.length - 1)
        : '0.00';
    state = state.copyWith(amount: next);
  }

  void toggleType() => state = state.copyWith(type: state.type.toggled);

  void toggleMethod() => state = state.copyWith(method: state.method.toggled);

  void setDescription(String description) =>
      state = state.copyWith(description: description);

  void setDate(DateTime date) => state = state.copyWith(dateTime: date);

  void setCategory(Category category) =>
      state = state.copyWith(category: category);

  /// Preselecciona la primera categoría si aún no se eligió una real (RN-006).
  void setDefaultCategoryIfUnset(Category category) {
    if (!state.hasCategory) setCategory(category);
  }

  /// Valida y guarda el movimiento (RN-001). Tras guardar hace **reset parcial**
  /// (solo monto y descripción; tipo/método/fecha/categoría se conservan, RN-010).
  Future<SaveResult> save() async {
    if (!isValidAmountInput(state.amount)) return SaveResult.invalidAmount;
    if (!state.hasCategory) return SaveResult.noCategory;

    final movement = Movement(
      id: 0,
      amountCents: parseAmountToCents(state.amount),
      description: state.description.isEmpty ? null : state.description,
      category: state.category,
      method: state.method,
      type: state.type,
      dateTime: state.dateTime,
    );
    await ref.read(addMovementProvider)(movement);

    state = state.copyWith(amount: '0.00', description: '');
    return SaveResult.success;
  }
}

final newMovementProvider =
    NotifierProvider<NewMovementNotifier, NewMovementState>(
  NewMovementNotifier.new,
);
