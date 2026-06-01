import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/cuantito_colors.dart';
import '../../domain/models/transaction_type.dart';

/// Teclado numérico del rediseño. Cuadrícula de 4 columnas × 4 filas:
/// ```
/// 1 2 3 ⌫
/// 4 5 6 ┌Egreso┐   (toggle de tipo, rowspan 2)
/// 7 8 9 └Ingreso┘
/// . 0 [ Guardar ]  (Guardar: colspan 2)
/// ```
/// El **método** ya no vive aquí (pasó a un chip); la columna 4 aloja el toggle
/// de tipo (egreso/ingreso). Cada tecla dispara **háptica**
/// (`HapticFeedback.selectionClick()`) como el `vibrate()` del origen.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.type,
    required this.amountIsZero,
    required this.saved,
    required this.onKey,
    required this.onBackspace,
    required this.onSelectType,
    required this.onSave,
  });

  final TransactionType type;
  final bool amountIsZero;
  final bool saved;
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final ValueChanged<TransactionType> onSelectType;
  final VoidCallback onSave;

  static const double _gap = 7;
  static const double _rowH = 66;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    final tColor = type == TransactionType.egreso ? c.expense : c.income;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = (constraints.maxWidth - _gap * 3) / 4;
        double x(int col) => col * (cellW + _gap);
        double y(int row) => row * (_rowH + _gap);
        final totalH = _rowH * 4 + _gap * 3;

        Widget at(double left, double top, double w, double h, Widget child) =>
            Positioned(left: left, top: top, width: w, height: h, child: child);

        return SizedBox(
          height: totalH,
          width: constraints.maxWidth,
          child: Stack(
            children: [
              // Dígitos 1–9.
              for (final (i, d) in const ['1', '2', '3'].indexed)
                at(x(i), y(0), cellW, _rowH, _DigitKey(d, onKey)),
              for (final (i, d) in const ['4', '5', '6'].indexed)
                at(x(i), y(1), cellW, _rowH, _DigitKey(d, onKey)),
              for (final (i, d) in const ['7', '8', '9'].indexed)
                at(x(i), y(2), cellW, _rowH, _DigitKey(d, onKey)),
              // Fila 4: punto y cero.
              at(x(0), y(3), cellW, _rowH,
                  _DigitKey('.', onKey, surface: c.surface1, fontSize: 30)),
              at(x(1), y(3), cellW, _rowH, _DigitKey('0', onKey)),
              // Backspace (col 4, fila 1).
              at(x(3), y(0), cellW, _rowH,
                  _PadKey(onTap: onBackspace, color: c.surface1,
                      child: Icon(Icons.backspace_outlined, color: c.textMedium, size: 22))),
              // Toggle de tipo (col 4, filas 2–3).
              at(x(3), y(1), cellW, _rowH * 2 + _gap,
                  _TypeToggle(type: type, onSelect: onSelectType)),
              // Guardar (colspan 2, fila 4).
              at(x(2), y(3), cellW * 2 + _gap, _rowH,
                  _SaveKey(color: tColor, dim: amountIsZero, saved: saved, onTap: onSave)),
            ],
          ),
        );
      },
    );
  }
}

/// Tecla con animación de pulsación (escala + superficie presionada) y háptica.
class _PadKey extends StatefulWidget {
  const _PadKey({
    required this.onTap,
    required this.child,
    this.color,
    this.pressedColor,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color? color;
  final Color? pressedColor;

  @override
  State<_PadKey> createState() => _PadKeyState();
}

class _PadKeyState extends State<_PadKey> {
  bool _pressed = false;

  void _down(_) => setState(() => _pressed = true);
  void _up([_]) => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    final base = widget.color ?? c.surface2;
    return GestureDetector(
      onTapDown: _down,
      onTapCancel: _up,
      onTapUp: _up,
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 70),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          decoration: BoxDecoration(
            color: _pressed ? (widget.pressedColor ?? c.surface3) : base,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey(this.value, this.onKey, {this.surface, this.fontSize = 24});

  final String value;
  final ValueChanged<String> onKey;
  final Color? surface;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return _PadKey(
      onTap: () => onKey(value),
      color: surface,
      child: Text(
        value,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

/// Toggle vertical de tipo: Egreso (arriba) / Ingreso (abajo). La mitad activa
/// se tiñe con el color del tipo; tocar una mitad selecciona ese tipo.
class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.onSelect});

  final TransactionType type;
  final ValueChanged<TransactionType> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    final isE = type == TransactionType.egreso;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Expanded(
            child: _half(
              context,
              active: isE,
              activeColor: c.expense,
              icon: '↑',
              label: 'EGRESO',
              onTap: () => onSelect(TransactionType.egreso),
              borderBottom: true,
            ),
          ),
          Expanded(
            child: _half(
              context,
              active: !isE,
              activeColor: c.income,
              icon: '↓',
              label: 'INGRESO',
              onTap: () => onSelect(TransactionType.ingreso),
            ),
          ),
        ],
      ),
    );
  }

  Widget _half(
    BuildContext context, {
    required bool active,
    required Color activeColor,
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool borderBottom = false,
  }) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: active ? activeColor : c.surface2,
          border: borderBottom
              ? const Border(bottom: BorderSide(color: Color(0x47000000), width: 1.5))
              : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon,
                style: TextStyle(
                  fontSize: 17,
                  height: 1,
                  color: active ? Colors.white : c.textMedium,
                )),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: active ? Colors.white : c.textMedium,
                )),
          ],
        ),
      ),
    );
  }
}

class _SaveKey extends StatelessWidget {
  const _SaveKey({
    required this.color,
    required this.dim,
    required this.saved,
    required this.onTap,
  });

  final Color color;
  final bool dim;
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return _PadKey(
      onTap: onTap,
      color: saved ? c.income : color,
      pressedColor: saved ? c.income : color,
      child: Opacity(
        opacity: dim && !saved ? 0.38 : 1,
        child: saved
            ? const Icon(Icons.check, color: Colors.white, size: 26)
            : const Text('Guardar',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}
