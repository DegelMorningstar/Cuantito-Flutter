import 'package:flutter/material.dart';

import '../../app/theme/cuantito_colors.dart';
import 'cuantito_sheet.dart';

/// Muestra el bottom sheet de fecha (rediseño): accesos rápidos Hoy/Ayer y
/// "Otra fecha" que revela un calendario en línea. Devuelve la fecha elegida o
/// `null` si se cierra sin elegir. No se permiten fechas futuras (RN-004).
Future<DateTime?> showDateSheet(
  BuildContext context, {
  required DateTime initial,
  required Color accent,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DateSheet(initial: initial, accent: accent),
  );
}

class _DateSheet extends StatefulWidget {
  const _DateSheet({required this.initial, required this.accent});

  final DateTime initial;
  final Color accent;

  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  bool _showCalendar = false;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    const monthsLong = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    String sub(DateTime d) => '${d.day} de ${monthsLong[d.month - 1]}';
    final isOther =
        !_sameDay(widget.initial, today) && !_sameDay(widget.initial, yesterday);

    return CuantitoSheet(
      title: 'Fecha',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _option(
              context,
              label: 'Hoy',
              sub: sub(today),
              selected: _sameDay(widget.initial, today),
              onTap: () => Navigator.of(context).pop(today),
            ),
            const SizedBox(height: 8),
            _option(
              context,
              label: 'Ayer',
              sub: sub(yesterday),
              selected: _sameDay(widget.initial, yesterday),
              onTap: () => Navigator.of(context).pop(yesterday),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: c.hairline, height: 1),
            ),
            _option(
              context,
              label: 'Otra fecha',
              sub: isOther ? sub(widget.initial) : '···',
              selected: isOther,
              onTap: () => setState(() => _showCalendar = !_showCalendar),
            ),
            if (_showCalendar)
              Theme(
                // El calendario hereda el acento del tipo de movimiento.
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context)
                      .colorScheme
                      .copyWith(primary: widget.accent),
                ),
                child: CalendarDatePicker(
                  initialDate: widget.initial.isAfter(today) ? today : widget.initial,
                  firstDate: DateTime(2000),
                  lastDate: today,
                  onDateChanged: (d) => Navigator.of(context).pop(d),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required String label,
    required String sub,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final c = Theme.of(context).extension<CuantitoColors>()!;
    return Material(
      color: selected ? widget.accent.withValues(alpha: 0.14) : c.surface2,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? widget.accent.withValues(alpha: 0.45)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Theme.of(context).colorScheme.onSurface
                            : c.textMedium,
                      )),
              Text(sub,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: c.textDim)),
            ],
          ),
        ),
      ),
    );
  }
}
