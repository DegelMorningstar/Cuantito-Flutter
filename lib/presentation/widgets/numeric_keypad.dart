import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/cuantito_colors.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/models/transaction_type.dart';

/// Teclado numérico propio (porta `TecladoNumerico.kt`): dígitos + `.`,
/// backspace, toggles de método/tipo y botón Guardar. Cada pulsación dispara
/// **háptica** (`HapticFeedback`), como el `vibrate()` del origen.
///
/// Disposición (4 columnas):
/// ```
/// 1 2 3 ⌫
/// 4 5 6 [método]
/// 7 8 9 [tipo]
/// . 0 [  Guardar  ]
/// ```
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.method,
    required this.type,
    required this.onKey,
    required this.onBackspace,
    required this.onSave,
    required this.onToggleMethod,
    required this.onToggleType,
  });

  final PaymentMethod method;
  final TransactionType type;
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onSave;
  final VoidCallback onToggleMethod;
  final VoidCallback onToggleType;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cuantito = Theme.of(context).extension<CuantitoColors>()!;
    final methodColor = method == PaymentMethod.debito
        ? cuantito.debit
        : cuantito.credit;
    final typeColor = type == TransactionType.ingreso
        ? cuantito.income
        : cuantito.expense;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row([
            _digit('1'),
            _digit('2'),
            _digit('3'),
            _KeypadButton(
              onPressed: onBackspace,
              child: Icon(Icons.backspace_outlined, color: colors.primary),
            ),
          ]),
          _row([
            _digit('4'),
            _digit('5'),
            _digit('6'),
            _KeypadButton(
              onPressed: onToggleMethod,
              color: methodColor,
              child: _label(method.label),
            ),
          ]),
          _row([
            _digit('7'),
            _digit('8'),
            _digit('9'),
            _KeypadButton(
              onPressed: onToggleType,
              color: typeColor,
              child: _label(type.label),
            ),
          ]),
          _row([
            _digit('.'),
            _digit('0'),
            _KeypadButton(
              flex: 2,
              onPressed: onSave,
              color: colors.primary,
              child: _label('Guardar'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) => Row(children: children);

  Widget _digit(String value) =>
      _KeypadButton(onPressed: () => onKey(value), child: _label(value));

  Widget _label(String text) => Text(text);
}

/// Botón del teclado: ocupa `flex` columnas, dispara háptica y luego la acción.
class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.onPressed,
    required this.child,
    this.color,
    this.flex = 1,
  });

  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final isColored = color != null;
    final foreground = isColored
        ? _onColor(color!)
        : Theme.of(context).colorScheme.onSurface;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: color ?? Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              HapticFeedback.selectionClick();
              onPressed();
            },
            child: SizedBox(
              height: 60,
              child: Center(
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(color: foreground),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Color de texto/icono legible sobre un fondo de color.
  Color _onColor(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? Colors.white
          : Colors.black;
}
