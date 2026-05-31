/// Formateadores de presentación (moneda y fechas) con locale **es-MX / MXN**
/// (decisión F0). Centralizados aquí para evitar el locale mixto del origen
/// (R-06). F10 puede ampliarlos; F7/F8 ya los consumen.
library;

import 'package:intl/intl.dart';

final NumberFormat _currency = NumberFormat.currency(
  locale: 'es_MX',
  symbol: r'$',
);

/// Formatea un monto en **centavos** como moneda, p. ej. `123450 → "$1,234.50"`.
String formatCents(int cents) => _currency.format(cents / 100);

/// Nombres de mes en español (1 = enero), capitalizados para el selector.
const List<String> _monthNames = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

/// Nombre del mes (1–12) capitalizado, p. ej. `5 → "Mayo"`.
String monthName(int month) => _monthNames[month - 1];

/// Fecha larga en español, p. ej. `"5 de mayo, 2026"` (equivale al
/// `"d 'de' MMMM, yyyy"` del origen).
String formatLongDate(DateTime date) =>
    '${date.day} de ${_monthNames[date.month - 1].toLowerCase()}, ${date.year}';
