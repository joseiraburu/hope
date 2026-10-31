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
