// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

const _monthsEs = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];
const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _daysEs = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _two(int n) => n.toString().padLeft(2, '0');

/// «sáb 31 oct 2026 · 14:24»
String formatDateTime(DateTime dt, String lang) {
  final d = dt.toLocal();
  final en = lang == 'en';
  final day = (en ? _daysEn : _daysEs)[d.weekday - 1];
  final month = (en ? _monthsEn : _monthsEs)[d.month - 1];
  final time = '${_two(d.hour)}:${_two(d.minute)}';
  return en
      ? '$day $month ${d.day}, ${d.year} · $time'
      : '$day ${d.day} $month ${d.year} · $time';
}

/// «31 oct 2026»
String formatDate(DateTime dt, String lang) {
  final d = dt.toLocal();
  final month = (lang == 'en' ? _monthsEn : _monthsEs)[d.month - 1];
  return lang == 'en' ? '$month ${d.day}, ${d.year}' : '${d.day} $month ${d.year}';
}

/// «32 %» o «32,5 %» (en inglés «32.5%»).
String formatPct(double pct, String lang) {
  final rounded = (pct * 10).round() / 10;
  var text = rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toStringAsFixed(1);
  if (lang == 'en') return '$text%';
  text = text.replaceAll('.', ',');
  return '$text %';
}

/// Número con hasta [decimals] decimales, sin ceros sobrantes: «6», «6,3».
String formatNumber(double v, String lang, {int decimals = 1}) {
  final factor = _pow10(decimals);
  final rounded = (v * factor).round() / factor;
  var text = rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toStringAsFixed(decimals).replaceFirst(RegExp(r'0+$'), '');
  if (lang != 'en') text = text.replaceAll('.', ',');
  return text;
}

/// Número con signo: «+1,2», «−0,5», «0».
String formatSigned(double v, String lang, {int decimals = 1}) {
  final text = formatNumber(v.abs(), lang, decimals: decimals);
  if (text == '0') return '0';
  return v > 0 ? '+$text' : '−$text';
}

double _pow10(int n) {
  var f = 1.0;
  for (var i = 0; i < n; i++) {
    f *= 10;
  }
  return f;
}

/// Lee un número escrito con coma o con punto («12,5» o «12.5»).
double? parseDecimal(String text) {
  final t = text.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

/// «9 nov – 15 nov 2026» o «30 nov – 6 dic 2026».
String formatDayRange(DateTime start, DateTime endInclusive, String lang) {
  final en = lang == 'en';
  final months = en ? _monthsEn : _monthsEs;
  final a = start.toLocal();
  final b = endInclusive.toLocal();
  final sameYear = a.year == b.year;
  final left = en ? '${months[a.month - 1]} ${a.day}' : '${a.day} ${months[a.month - 1]}';
  final right = en ? '${months[b.month - 1]} ${b.day}' : '${b.day} ${months[b.month - 1]}';
  return sameYear ? '$left – $right ${b.year}' : '$left ${a.year} – $right ${b.year}';
}

/// «Noviembre 2026».
String formatMonth(DateTime d, String lang) {
  const es = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto',
    'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
  const en = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'];
  return '${(lang == 'en' ? en : es)[d.month - 1]} ${d.year}';
}

/// Fecha corta para ejes: «9 nov» / «Nov 9».
String formatShortDate(DateTime d, String lang) {
  final m = (lang == 'en' ? _monthsEn : _monthsEs)[d.month - 1];
  return lang == 'en' ? '$m ${d.day}' : '${d.day} $m';
}

/// Mes corto para ejes: «nov 26».
String formatShortMonth(DateTime d, String lang) {
  final m = (lang == 'en' ? _monthsEn : _monthsEs)[d.month - 1];
  return '$m ${(d.year % 100).toString().padLeft(2, '0')}';
}

/// «2026-11-01» (para nombres de archivo).
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

/// Dosis con su unidad: «300 mg», «12,5 µg/h».
String formatDose(double dose, String unitName, String lang) =>
    '${formatNumber(dose, lang, decimals: 2)} $unitName';
