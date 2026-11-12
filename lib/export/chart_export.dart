// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../charts/aggregation.dart';
import '../charts/chart_model.dart';
import '../charts/chart_painter.dart';
import '../charts/params.dart';
import '../core/config.dart';
import '../core/version.dart';
import '../l10n/strings.dart';
import '../models/treatment.dart';
import '../utils/format.dart';
import '../widgets/logo.dart';
import 'gif_encoder.dart';
import 'render.dart';
import 'xlsx_writer.dart';

/// Todo lo que hace falta para exportar una gráfica.
class ChartExportInput {
  const ChartExportInput({
    required this.data,
    required this.mode,
    required this.enabled,
    required this.showLanes,
    required this.s,
    required this.lang,
    required this.config,
    required this.medicationName,
  });

  final ChartData data;

  /// Vista combinada o por parámetro (la tabla se exporta como combinada).
  final ChartMode mode;
  final Set<Param> enabled;
  final bool showLanes;
  final S s;
  final String lang;
  final AppConfig config;
  final String Function(Treatment t) medicationName;

  ChartMode get drawMode => mode == ChartMode.perParam ? ChartMode.perParam : ChartMode.combined;

  String get rangeText => formatDayRange(data.from, data.to, lang);

  String get groupingText => switch (data.grouping) {
        Grouping.day => s.groupedByDay,
        Grouping.week => s.groupedByWeek,
        Grouping.month => s.groupedByMonth,
      };

  /// «HOPE_2026-09-01_2026-11-30».
  String get baseName => 'HOPE_${isoDate(data.from)}_${isoDate(data.to)}';

  List<Treatment> get treatments => [for (final l in data.lanes) ...l.treatments]
    ..sort((a, b) => a.start.compareTo(b.start));
}

TextStyle _style(double size, Color color, {FontWeight? weight}) =>
    TextStyle(fontSize: size, color: color, fontWeight: weight, fontFamily: 'Roboto', height: 1.25);

/// Texto de los valores de un periodo: «Dolor 6,2/10 · Superficie 18 %...».
String periodValuesText(ChartData data, int i, S s, String lang, Set<Param> enabled) {
  final st = data.periods[i].stats;
  return [
    for (final p in Param.values)
      if (enabled.contains(p) && st[p]?.mean != null) '${paramName(p, s)} ${formatParam(p, st[p]!.mean!, lang)}'
  ].join(' · ');
}

/// Dibuja la gráfica como imagen independiente (título, leyenda, gráfica,
/// valores bajo el cursor y avisos). Se usa en el PNG, el GIF y el PDF.
void paintChartCard(Canvas canvas, Size size, ChartExportInput input, {double? cursorFraction}) {
  final fs = size.width / 62;
  final style = ChartStyle.of(Brightness.light, fontSize: fs, fontFamily: 'Roboto');
  final s = input.s;
  final lang = input.lang;
  canvas.drawRect(Offset.zero & size, Paint()..color = style.background);
  final pad = size.width * 0.04;
  var y = pad;

  // Cabecera.
  final logoH = fs * 3.2;
  paintHopeLogo(canvas, Rect.fromLTWH(pad, y, logoH * kLogoAspect, logoH), style.text);
  final tx = pad + logoH * kLogoAspect + fs;
  paintText(canvas, 'HOPE · ${s.chartTitle}', Offset(tx, y), _style(fs * 1.55, style.text, weight: FontWeight.w700));
  paintText(canvas, '${input.rangeText} · ${input.groupingText}', Offset(tx, y + fs * 2.0),
      _style(fs * 1.0, style.subtleText));
  y += logoH + fs * 1.0;

  // Leyenda.
  var lx = pad;
  final legendStyle = _style(fs * 0.95, style.text);
  for (final p in Param.values) {
    if (!input.enabled.contains(p)) continue;
    final name = paramName(p, s);
    final w = measureText(name, legendStyle);
    if (lx + fs * 3 + w > size.width - pad) {
      lx = pad;
      y += fs * 1.6;
    }
    paintLegendSample(canvas, Rect.fromLTWH(lx, y + fs * 0.15, fs * 2.2, fs * 1.0), p, style);
    paintText(canvas, name, Offset(lx + fs * 2.6, y), legendStyle);
    lx += fs * 2.6 + w + fs * 1.4;
  }
  y += fs * 2.0;

  // Pie de página y panel del cursor.
  final footerH = fs * 3.4;
  final panelH = cursorFraction == null ? 0.0 : fs * 4.8;
  final chartRect = Rect.fromLTRB(pad * 0.4, y, size.width - pad * 0.6, size.height - pad - footerH - panelH);
  canvas.save();
  canvas.translate(chartRect.left, chartRect.top);
  paintChart(
    canvas,
    chartRect.size,
    data: input.data,
    style: style,
    mode: input.drawMode,
    enabled: input.enabled,
    showLanes: input.showLanes,
    s: s,
    lang: lang,
    cursorFraction: cursorFraction,
  );
  canvas.restore();

  if (cursorFraction != null) {
    final idx = input.data.nearestDataIndex(cursorFraction);
    final py = chartRect.bottom + fs * 0.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(pad, py, size.width - pad * 2, panelH - fs * 0.6),
          Radius.circular(fs * 0.6)),
      Paint()..color = style.laneBackground,
    );
    if (idx != null) {
      final p = input.data.periods[idx];
      paintText(canvas, '${input.data.periodLabel(idx, s, lang)} · ${s.nRecords(p.count)}',
          Offset(pad + fs * 0.8, py + fs * 0.5), _style(fs * 1.0, style.text, weight: FontWeight.w700),
          maxWidth: size.width - pad * 2 - fs * 1.6);
      paintText(canvas, periodValuesText(input.data, idx, s, lang, input.enabled),
          Offset(pad + fs * 0.8, py + fs * 1.9), _style(fs * 0.92, style.text),
          maxWidth: size.width - pad * 2 - fs * 1.6);
      final active = input.data.treatmentsIn(idx);
      if (input.showLanes && active.isNotEmpty) {
        final names = active.map((t) => input.medicationName(t)).toSet().join(', ');
        paintText(canvas, '${s.activeTreatments}: $names', Offset(pad + fs * 0.8, py + fs * 3.1),
            _style(fs * 0.9, style.subtleText),
            maxWidth: size.width - pad * 2 - fs * 1.6);
      }
    }
  }

  final noteStyle = _style(fs * 0.78, style.subtleText);
  final fy = size.height - pad - footerH + fs * 0.4;
  final maxW = size.width - pad * 2;
  final notes = [
    if (input.drawMode == ChartMode.combined) s.relativeScaleNote,
    s.causalDisclaimer,
  ];
  var ny = fy;
  for (final n in notes) {
    final tp = TextPainter(
      text: TextSpan(text: n, style: noteStyle),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxW);
    tp.paint(canvas, Offset(pad, ny));
    ny += tp.height + fs * 0.2;
    tp.dispose();
  }
}

/// PNG de la gráfica completa (sin cursor).
Future<Uint8List> chartPng(ChartExportInput input, {int width = 1600, int height = 1000}) =>
    renderPng(width, height, (c, size) => paintChartCard(c, size, input));

/// GIF animado: el cursor recorre la gráfica de izquierda a derecha.
Future<Uint8List?> chartGif(
  ChartExportInput input, {
  int size = 1080,
  double seconds = 10,
  double fps = 15,
  void Function(double progress)? onProgress,
  bool Function()? isCancelled,
}) async {
  final data = input.data;
  if (data.isEmpty) return null;
  final first = data.fractionOfPeriod(data.dataIndices.first);
  final last = data.fractionOfPeriod(data.dataIndices.last);
  final frames = (seconds * fps).round();
  double fractionAt(int k) => frames <= 1 ? last : first + (last - first) * k / (frames - 1);

  // Paleta común a partir de varios fotogramas de muestra.
  final samples = <Uint8List>[];
  for (final k in [0, frames ~/ 2, frames - 1]) {
    samples.add(await renderRgba(size, size, (c, sz) => paintChartCard(c, sz, input, cursorFraction: fractionAt(k))));
  }
  final palette = GifPalette.fromFrames(samples);
  final writer = GifWriter(width: size, height: size, palette: palette, fps: fps);
  for (var k = 0; k < frames; k++) {
    if (isCancelled?.call() ?? false) return null;
    final rgba = await renderRgba(size, size, (c, sz) => paintChartCard(c, sz, input, cursorFraction: fractionAt(k)));
    writer.addFrame(rgba);
    onProgress?.call((k + 1) / frames);
    await yieldToUi();
  }
  return writer.finish();
}

String _medNames(ChartExportInput input, List<Treatment> list) =>
    list.map((t) => input.medicationName(t)).toSet().join(', ');

/// Hoja de cálculo con resumen, registros, tratamientos e información.
Uint8List chartXlsx(ChartExportInput input, {DateTime? now}) {
  final s = input.s;
  final lang = input.lang;
  final config = input.config;
  final data = input.data;

  final summaryHeader = <String>[s.colPeriodStart, s.colPeriodEnd, s.records];
  for (final p in Param.values) {
    final name = switch (p) {
      Param.pain => s.colPain,
      Param.surface => s.colSurface,
      Param.eventIntensity => s.colEventIntensity,
      Param.eventFrequency => s.colEventFrequency,
    };
    summaryHeader
      ..add(s.colStat(name, s.mean.toLowerCase()))
      ..add(s.colStat(name, s.minimum.toLowerCase()))
      ..add(s.colStat(name, s.maximum.toLowerCase()));
  }
  summaryHeader.add(s.colActiveTreatments);
  final summaryRows = <List<Object?>>[];
  for (var i = 0; i < data.periods.length; i++) {
    final p = data.periods[i];
    final row = <Object?>[
      XlsxDateTime(p.start, withTime: false),
      XlsxDateTime(p.lastDay, withTime: false),
      p.count,
    ];
    for (final param in Param.values) {
      final st = p.stats[param];
      row
        ..add(st?.mean == null ? null : XlsxDecimal(st!.mean!))
        ..add(st?.min == null ? null : XlsxDecimal(st!.min!))
        ..add(st?.max == null ? null : XlsxDecimal(st!.max!));
    }
    final active = data.treatmentsIn(i);
    row.add(active.isEmpty ? null : _medNames(input, active));
    summaryRows.add(row);
  }

  final records = [for (final p in data.periods) ...p.records]
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  final recordRows = <List<Object?>>[
    for (final r in records)
      [
        XlsxDateTime(r.dateTime),
        r.sex == 'male' ? s.male : s.female,
        r.painIntensity,
        config.describeParts(r.zones, lang).join(', '),
        r.zoneCount,
        XlsxDecimal(r.surfacePct),
        r.eventIntensity,
        paramValue(Param.eventFrequency, r)?.round(),
        r.eventTypes.map((t) => config.eventTypeById[t]?.name(lang) ?? t).join(', '),
        r.note.isEmpty ? null : r.note,
      ]
  ];

  final treatmentRows = <List<Object?>>[
    for (final t in input.treatments)
      [
        input.medicationName(t),
        config.routeName(t.route, lang),
        XlsxDecimal(t.dose),
        config.unitName(t.unit, lang),
        XlsxDateTime(t.start),
        t.end == null ? null : XlsxDateTime(t.end!),
        t.isPunctual ? s.punctual : s.colPeriodKind,
        t.schedule.isEmpty ? null : t.schedule,
        [
          for (final e in t.adverseEffects) config.adverseEffectName(e, lang),
          if (t.adverseOther.isNotEmpty) t.adverseOther,
        ].join(', '),
        t.notes.isEmpty ? null : t.notes,
      ]
  ];

  final exported = now ?? DateTime.now();
  final infoRows = <List<Object?>>[
    [s.infoApp, 'HOPE $appVersion'],
    [s.infoRange, input.rangeText],
    [s.infoGrouping, input.groupingText],
    [s.infoExported, XlsxDateTime(exported)],
    [s.infoScale, s.relativeScaleNote],
    [s.infoColumns, s.infoColumnsText],
    [s.infoNotice, '${s.medicalDisclaimer} ${s.causalDisclaimer}'],
  ];

  return buildXlsx([
    XlsxSheet(
      name: s.sheetSummary,
      header: summaryHeader,
      rows: summaryRows,
      columnWidths: [14, 14, 10, for (var i = 0; i < 12; i++) 12, 30],
    ),
    XlsxSheet(
      name: s.sheetRecords,
      header: [
        s.colDateTime,
        s.colSilhouette,
        s.colPain,
        s.colZones,
        s.colZoneCount,
        s.colSurface,
        s.colEventIntensity,
        s.colEventFrequency,
        s.colEventTypes,
        s.colNote,
      ],
      rows: recordRows,
      columnWidths: const [17, 10, 12, 40, 10, 12, 14, 14, 30, 40],
      wrapColumns: const {3, 9},
    ),
    XlsxSheet(
      name: s.sheetTreatments,
      header: [
        s.colMedication,
        s.colRoute,
        s.colDose,
        s.colUnit,
        s.colStart,
        s.colEnd,
        s.colKind,
        s.schedule,
        s.adverseEffects,
        s.notes,
      ],
      rows: treatmentRows,
      columnWidths: const [18, 24, 10, 10, 17, 17, 10, 18, 28, 40],
      wrapColumns: const {8, 9},
    ),
    XlsxSheet(
      name: s.sheetInfo,
      header: [s.sheetInfo, ''],
      rows: infoRows,
      columnWidths: const [24, 100],
      wrapColumns: const {1},
    ),
  ], time: exported);
}

/// Sustituye los caracteres que la fuente estándar del PDF no puede dibujar.
String pdfSafe(String text) {
  const extra = {
    0x20AC, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, 0x02C6, 0x2030, 0x0160, //
    0x2039, 0x0152, 0x017D, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
    0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x017E, 0x0178,
  };
  final b = StringBuffer();
  for (final r in text.runes) {
    // La fuente estándar del PDF no dibuja guiones largos, comillas
    // tipográficas ni puntos suspensivos (salían como un cuadradito).
    if (r == 0x2212 || r == 0x2013 || r == 0x2014) {
      b.write('-');
    } else if (r == 0x2026) {
      b.write('...');
    } else if (r == 0x2018 || r == 0x2019) {
      b.write("'");
    } else if (r == 0x201C || r == 0x201D) {
      b.write('"');
    } else if (r == 0x00B5 || r == 0x03BC) {
      b.writeCharCode(0x00B5);
    } else if ((r >= 0x20 && r < 0x7F) || (r >= 0xA0 && r <= 0xFF) || extra.contains(r)) {
      b.writeCharCode(r);
    } else if (r == 0x0A) {
      b.write('\n');
    } else {
      b.write('?');
    }
  }
  return b.toString();
}

/// Informe PDF para la consulta: gráfica, resumen y tratamientos.
Future<Uint8List> chartPdf(ChartExportInput input, {DateTime? now}) async {
  final s = input.s;
  final lang = input.lang;
  final data = input.data;
  final png = await renderPng(1800, 1100, (c, size) => paintChartCard(c, size, input));
  final image = pw.MemoryImage(png);
  final generated = now ?? DateTime.now();
  String t(String v) => pdfSafe(v);

  final summary = <List<String>>[
    for (var i = 0; i < data.periods.length; i++)
      if (data.periods[i].hasData)
        [
          t(data.periodLabel(i, s, lang)),
          '${data.periods[i].count}',
          for (final p in Param.values)
            data.periods[i].stats[p]?.mean == null
                ? '-'
                : t(formatParam(p, data.periods[i].stats[p]!.mean!, lang)),
        ]
  ];
  final treatments = <List<String>>[
    for (final tr in input.treatments)
      [
        t(input.medicationName(tr)),
        t(input.config.routeName(tr.route, lang)),
        t(formatDose(tr.dose, input.config.unitName(tr.unit, lang), lang)),
        t(formatDateTime(tr.start, lang)),
        tr.end == null ? t(s.punctual) : t(formatDateTime(tr.end!, lang)),
        t([
          for (final e in tr.adverseEffects) input.config.adverseEffectName(e, lang),
          if (tr.adverseOther.isNotEmpty) tr.adverseOther,
        ].join(', ')),
      ]
  ];

  final doc = pw.Document(title: t(s.reportTitle), author: 'HOPE', creator: 'HOPE $appVersion');
  final headerStyle = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
  const cellStyle = pw.TextStyle(fontSize: 9);
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    footer: (ctx) => pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
    ),
    build: (ctx) => [
      pw.Text(t(s.reportTitle), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Text(t('${input.rangeText} · ${input.groupingText}'), style: const pw.TextStyle(fontSize: 10)),
      pw.Text(t(s.generatedOn(formatDateTime(generated, lang))), style: const pw.TextStyle(fontSize: 9)),
      pw.SizedBox(height: 12),
      pw.Image(image),
      pw.SizedBox(height: 16),
      pw.Text(t(s.summaryByPeriod), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      if (summary.isEmpty)
        pw.Text(t(s.noDataInRange), style: cellStyle)
      else
        pw.TableHelper.fromTextArray(
          headers: [
            t(s.period),
            t(s.records),
            for (final p in Param.values) t(paramName(p, s)),
          ],
          data: summary,
          headerStyle: headerStyle,
          cellStyle: cellStyle,
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1EDE8)),
          cellAlignment: pw.Alignment.centerLeft,
        ),
      if (treatments.isNotEmpty) ...[
        pw.SizedBox(height: 16),
        pw.Text(t(s.treatments), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: [
            t(s.colMedication),
            t(s.colRoute),
            t(s.colDose),
            t(s.colStart),
            t(s.colEnd),
            t(s.adverseEffects),
          ],
          data: treatments,
          headerStyle: headerStyle,
          cellStyle: cellStyle,
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1EDE8)),
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
      pw.SizedBox(height: 16),
      pw.Text(t(s.causalDisclaimer), style: const pw.TextStyle(fontSize: 8)),
      pw.SizedBox(height: 4),
      pw.Text(t(s.medicalDisclaimer), style: const pw.TextStyle(fontSize: 8)),
    ],
  ));
  return doc.save();
}
