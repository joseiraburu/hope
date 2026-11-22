// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.
//
// Informe completo exportable: un único archivo HTML que sirve para dos
// cosas a la vez.
//  * Se lee sin HOPE: cualquier navegador lo abre (y lo imprime o lo guarda
//    en PDF), así que se puede enviar al médico tal cual.
//  * Se carga en otro dispositivo: lleva dentro la copia de seguridad
//    completa en JSON, en un bloque <script type="application/json"> que el
//    navegador no muestra ni ejecuta.

import '../charts/full_report_text.dart';
import '../core/config.dart';
import '../core/version.dart';
import '../data/backup.dart';
import '../data/merge.dart' show DataCounts;
import '../l10n/strings.dart';
import '../models/food.dart';
import '../models/treatment.dart';
import '../utils/format.dart';

/// Días del resumen que encabeza el informe.
const int fullExportSummaryDays = 30;

/// Nombre del archivo: «Hope_informe_2026-11-22.html».
String fullExportFileName(DateTime now) => 'Hope_informe_${isoDate(now)}.html';

/// Lo necesario para escribir el informe.
class FullExportInput {
  const FullExportInput({
    required this.data,
    required this.config,
    required this.s,
    required this.lang,
    required this.foodName,
    required this.medicationName,
    required this.summary,
    this.now,
  });

  /// Todos los datos (los ajustes, sin la clave del servicio de IA).
  final BackupData data;
  final AppConfig config;
  final S s;
  final String lang;
  final String Function(String id) foodName;
  final String Function(Treatment t) medicationName;

  /// Informe de los últimos [fullExportSummaryDays] días.
  final ReportWriter summary;
  final DateTime? now;
}

/// Escapa un texto para ponerlo en HTML.
String htmlEscape(String text) {
  final b = StringBuffer();
  for (final rune in text.runes) {
    switch (rune) {
      case 0x26:
        b.write('&amp;');
      case 0x3C:
        b.write('&lt;');
      case 0x3E:
        b.write('&gt;');
      case 0x22:
        b.write('&quot;');
      case 0x27:
        b.write('&#39;');
      default:
        b.writeCharCode(rune);
    }
  }
  return b.toString();
}

/// JSON listo para ir dentro de <script>: ningún «<» puede cerrar el bloque.
/// Dentro de un JSON solo aparece en textos, donde «\u003c» es equivalente.
String _scriptSafeJson(String json) => json.replaceAll('<', r'\u003c');

const String _css = '''
:root { color-scheme: light; }
* { box-sizing: border-box; }
body { margin: 0; font-family: -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  color: #1f2328; background: #faf8f5; line-height: 1.45; font-size: 15px; }
main { max-width: 1100px; margin: 0 auto; padding: 24px 18px 48px; }
header { border-bottom: 3px solid #3d5a80; padding-bottom: 12px; margin-bottom: 18px; }
h1 { font-size: 26px; margin: 0 0 4px; letter-spacing: .5px; }
h2 { font-size: 20px; margin: 32px 0 8px; padding: 6px 10px; background: #f1ede8; border-radius: 6px; }
h3 { font-size: 16px; margin: 18px 0 6px; }
p { margin: 4px 0; }
.muted { color: #5f6368; font-size: 13px; }
.notice { background: #fff3e0; border-radius: 6px; padding: 10px 12px; margin: 12px 0; font-weight: 600; }
.tag { display: inline-block; background: #fff3e0; border-radius: 4px; padding: 1px 6px; font-size: 12px;
  font-weight: 700; margin-left: 6px; }
nav ul { list-style: none; padding: 0; margin: 8px 0 0; display: flex; flex-wrap: wrap; gap: 6px 14px; }
nav a { color: #3d5a80; }
ul.lines { margin: 4px 0 8px; padding-left: 20px; }
ul.lines li.missing { color: #5f6368; font-style: italic; }
.table { overflow-x: auto; }
table { border-collapse: collapse; width: 100%; background: #fff; font-size: 13.5px; }
th, td { border: 1px solid #ddd6cc; padding: 5px 7px; text-align: left; vertical-align: top; }
th { background: #f1ede8; position: sticky; top: 0; }
td.n { text-align: right; white-space: nowrap; }
td.d { white-space: nowrap; }
.q { display: inline-block; min-width: 22px; text-align: center; color: #fff; border-radius: 11px;
  padding: 0 6px; font-weight: 700; margin-right: 4px; }
.q1 { background: #5d4037; } .q2 { background: #8d6e63; } .q3 { background: #2e7d32; }
.q4 { background: #00897b; } .q5 { background: #1565c0; }
footer { margin-top: 36px; border-top: 1px solid #ddd6cc; padding-top: 10px; }
@media print {
  body { background: #fff; font-size: 11pt; }
  main { max-width: none; padding: 0; }
  nav, .noprint { display: none; }
  th { position: static; }
  tr { page-break-inside: avoid; }
  h2 { page-break-after: avoid; }
}
''';

/// Escribe el informe completo en HTML (con los datos para importarlos).
String fullExportHtml(FullExportInput input) {
  final s = input.s;
  final lang = input.lang;
  final config = input.config;
  final data = input.data;
  final now = input.now ?? DateTime.now();
  String h(String v) => htmlEscape(v);
  String dash(String v) => v.trim().isEmpty ? '—' : h(v.trim());

  final records = [...data.records]..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  final bowel = [...?data.bowel]..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  final sleep = [...?data.sleep]..sort((a, b) => b.date.compareTo(a.date));
  final foodDays = [for (final d in data.foodDays ?? const <FoodDay>[]) if (!d.isEmpty) d]
    ..sort((a, b) => b.date.compareTo(a.date));
  final treatments = [...data.treatments]..sort((a, b) => b.start.compareTo(a.start));

  // Fechas que abarcan los datos.
  final dates = <DateTime>[
    for (final r in records) r.dateTime,
    for (final e in bowel) e.dateTime,
    for (final e in sleep) e.date,
    for (final d in foodDays) d.date,
    for (final t in treatments) t.start,
  ];
  DateTime? first;
  DateTime? last;
  for (final d in dates) {
    if (first == null || d.isBefore(first)) first = d;
    if (last == null || d.isAfter(last)) last = d;
  }

  final b = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="${h(lang)}">')
    ..writeln('<head>')
    ..writeln('<meta charset="utf-8">')
    ..writeln('<meta name="viewport" content="width=device-width, initial-scale=1">')
    ..writeln('<meta name="generator" content="HOPE ${h(appVersion)}">')
    ..writeln('<title>${h('${s.fullReportTitle} · ${isoDate(now)}')}</title>')
    ..writeln('<style>$_css</style>')
    ..writeln('</head>')
    ..writeln('<body>')
    ..writeln('<main>');

  // Cabecera.
  b
    ..writeln('<header>')
    ..writeln('<h1>${h(s.fullReportTitle)}</h1>')
    ..writeln('<p>${h(s.exportCompleteRecord)}</p>')
    ..writeln('<p class="muted">${h(s.generatedOn(formatDateTime(now, lang)))} · HOPE ${h(appVersion)}</p>');
  if (first != null && last != null) {
    b.writeln('<p class="muted">${h(s.exportDataRange(formatDate(first, lang), formatDate(last, lang)))}</p>');
  }
  b
    ..writeln('<p class="muted">${h(s.dataCounts(DataCounts(
          pain: records.length,
          bowel: bowel.length,
          sleep: sleep.length,
          foodDays: foodDays.length,
          treatments: treatments.length,
        )))}</p>')
    ..writeln('<p class="notice">${h(s.reportNotice)}</p>')
    ..writeln('<nav><strong>${h(s.exportContents)}</strong><ul>')
    ..writeln('<li><a href="#resumen">${h(s.exportSummaryTitle(fullExportSummaryDays))}</a></li>')
    ..writeln('<li><a href="#dolor">${h(s.exportPainTitle)}</a></li>')
    ..writeln('<li><a href="#deposiciones">${h(s.bowel)}</a></li>')
    ..writeln('<li><a href="#sueno">${h(s.sleep)}</a></li>')
    ..writeln('<li><a href="#alimentacion">${h(s.food)}</a></li>')
    ..writeln('<li><a href="#medicacion">${h(s.tileMedication)}</a></li>')
    ..writeln('</ul></nav>')
    ..writeln('</header>');

  // Resumen de los últimos días (el mismo que «Generar informe»).
  final report = input.summary.report;
  b
    ..writeln('<section id="resumen">')
    ..writeln('<h2>${h(s.exportSummaryTitle(fullExportSummaryDays))}</h2>')
    ..writeln('<p class="muted">${h(formatDayRange(report.from, report.to, lang))}</p>');
  for (final block in input.summary.blocks()) {
    b.write('<h3>${h(block.title)}');
    if (block.insufficient) b.write('<span class="tag">${h(s.insufficientData)}</span>');
    b
      ..writeln('</h3>')
      ..writeln('<ul class="lines">');
    for (final line in block.lines) {
      b.writeln('<li>${h(line)}</li>');
    }
    for (final line in block.missing) {
      b.writeln('<li class="missing">${h('${s.insufficientData}: $line')}</li>');
    }
    b.writeln('</ul>');
  }
  b
    ..writeln('<h3>${h(s.reportConclusions)}</h3>')
    ..writeln('<ul class="lines">');
  for (final c in input.summary.conclusions()) {
    b.writeln('<li>${h(c)}</li>');
  }
  b
    ..writeln('</ul>')
    ..writeln('</section>');

  void table(List<String> header, List<List<String>> rows, {Set<int> numeric = const {}, Set<int> nowrap = const {}}) {
    if (rows.isEmpty) {
      b.writeln('<p class="muted">${h(s.noData)}</p>');
      return;
    }
    b
      ..writeln('<div class="table"><table>')
      ..write('<thead><tr>');
    for (final c in header) {
      b.write('<th>${h(c)}</th>');
    }
    b.writeln('</tr></thead><tbody>');
    for (final row in rows) {
      b.write('<tr>');
      for (var i = 0; i < row.length; i++) {
        final cls = numeric.contains(i) ? ' class="n"' : (nowrap.contains(i) ? ' class="d"' : '');
        // Las celdas ya vienen escapadas.
        b.write('<td$cls>${row[i]}</td>');
      }
      b.writeln('</tr>');
    }
    b.writeln('</tbody></table></div>');
  }

  // Dolor.
  b
    ..writeln('<section id="dolor">')
    ..writeln('<h2>${h(s.exportPainTitle)} (${records.length})</h2>');
  table(
    [
      s.colDateTime,
      s.colPain,
      s.colZones,
      s.colSurface,
      s.colEventIntensity,
      s.colEventFrequency,
      s.colEventTypes,
      s.colNote,
    ],
    [
      for (final r in records)
        [
          h(formatDateTime(r.dateTime, lang)),
          '${r.painIntensity}',
          dash(config.describeParts(r.zones, lang).join(', ')),
          h(formatPct(r.surfacePct, lang)),
          '${r.eventIntensity}',
          r.eventIntensity > 0 && r.eventTypes.isNotEmpty ? '${r.eventFrequency}' : '—',
          r.eventIntensity > 0
              ? dash(config.orderedEventTypes(r.eventTypes).map((t) => config.eventTypeById[t]?.name(lang) ?? t).join(', '))
              : '—',
          dash(r.note),
        ],
    ],
    numeric: const {1, 3, 4, 5},
    nowrap: const {0},
  );
  b.writeln('</section>');

  // Deposiciones.
  String quality(int q) => '<span class="q q$q">$q</span>${h(s.bowelQualityName(q))}';
  b
    ..writeln('<section id="deposiciones">')
    ..writeln('<h2>${h(s.bowel)} (${bowel.length})</h2>')
    ..writeln('<p class="muted">${h(s.bowelScaleText)}</p>');
  table(
    [s.colDateTime, s.bowelQuality, s.colNote],
    [
      for (final e in bowel) [h(formatDateTime(e.dateTime, lang)), quality(e.quality), dash(e.note)],
    ],
    nowrap: const {0},
  );
  b.writeln('</section>');

  // Sueño.
  b
    ..writeln('<section id="sueno">')
    ..writeln('<h2>${h(s.sleep)} (${sleep.length})</h2>')
    ..writeln('<p class="muted">${h(s.exportSleepNote)}</p>');
  table(
    [s.sleepNight, s.sleepQuality, s.exportNightPain, s.colNote],
    [
      for (final e in sleep)
        [
          h(s.nightOf(formatShortDate(e.nightStart, lang), formatDate(e.date, lang))),
          h(s.sleepQualityValue(e.quality)),
          e.withPain == null ? '—' : h(e.withPain! ? s.withPain : s.withoutPain),
          dash(e.note),
        ],
    ],
    nowrap: const {0},
  );
  b.writeln('</section>');

  // Alimentación.
  String meal(FoodDay d, MealSlot slot) {
    final m = d.meal(slot);
    if (m.skipped) return '<em>${h(s.mealSkipped)}</em>';
    if (m.foods.isEmpty) return '—';
    final foods = h(m.foods.map(input.foodName).join(', '));
    return m.time == null ? foods : '<span class="muted">${h(m.time!)}</span> $foods';
  }

  b
    ..writeln('<section id="alimentacion">')
    ..writeln('<h2>${h(s.food)} (${foodDays.length})</h2>');
  table(
    [s.foodDay, for (final slot in MealSlot.values) s.meal(slot)],
    [
      for (final d in foodDays) [h(formatDayLong(d.date, lang)), for (final slot in MealSlot.values) meal(d, slot)],
    ],
    nowrap: const {0},
  );
  b.writeln('</section>');

  // Medicación.
  b
    ..writeln('<section id="medicacion">')
    ..writeln('<h2>${h(s.tileMedication)} (${treatments.length})</h2>');
  table(
    [s.colMedication, s.colRoute, s.colDose, s.colStart, s.colEnd, s.schedule, s.adverseEffects, s.notes],
    [
      for (final t in treatments)
        [
          h(input.medicationName(t)),
          h(config.routeName(t.route, lang)),
          h(formatDose(t.dose, config.unitName(t.unit, lang), lang)),
          h(formatDateTime(t.start, lang)),
          t.end == null ? h(s.punctual) : h(formatDateTime(t.end!, lang)),
          dash(t.schedule),
          dash([
            for (final e in t.adverseEffects) config.adverseEffectName(e, lang),
            if (t.adverseOther.trim().isNotEmpty) t.adverseOther.trim(),
          ].join(', ')),
          dash(t.notes),
        ],
    ],
    nowrap: const {3, 4},
  );
  b.writeln('</section>');

  // Pie: cómo cargarlo en otro dispositivo y aviso.
  b
    ..writeln('<footer>')
    ..writeln('<p class="muted">${h(s.exportImportHelp)}</p>')
    ..writeln('<p class="muted">${h(s.medicalDisclaimer)}</p>')
    ..writeln('</footer>')
    ..writeln('</main>');

  // Datos para importar (el navegador no los muestra).
  final json = encodeBackup(data, now: now);
  b
    ..writeln('<script type="application/json" id="$backupHtmlScriptId">')
    ..writeln(_scriptSafeJson(json))
    ..writeln('</script>')
    ..writeln('</body>')
    ..writeln('</html>');
  return b.toString();
}
