// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../charts/full_report.dart';
import '../charts/full_report_text.dart';
import '../core/version.dart';
import '../l10n/strings.dart';
import '../utils/format.dart';
import 'chart_export.dart' show pdfSafe;

const PdfColor _band = PdfColor.fromInt(0xFFF1EDE8);
const PdfColor _warning = PdfColor.fromInt(0xFFFFF3E0);
const PdfColor _muted = PdfColor.fromInt(0xFF5F6368);

/// Informe completo en PDF, para llevarlo a la consulta: los mismos
/// apartados y conclusiones que en la pantalla y, si se pidió, el análisis
/// con IA (marcado como tal).
Future<Uint8List> fullReportPdf({
  required FullReport report,
  required List<ReportBlock> blocks,
  required List<String> conclusions,
  required S s,
  required String lang,
  String? aiText,
  DateTime? now,
}) async {
  String t(String v) => pdfSafe(v);
  final generated = now ?? DateTime.now();
  final doc = pw.Document(title: t(s.fullReportTitle), author: 'HOPE', creator: 'HOPE $appVersion');
  final h2 = pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold);
  const body = pw.TextStyle(fontSize: 10, lineSpacing: 1.5);
  final missingStyle = pw.TextStyle(fontSize: 10, color: _muted, fontStyle: pw.FontStyle.italic);

  pw.Widget insufficientTag() => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        color: _warning,
        child: pw.Text(t(s.insufficientData), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      );

  List<pw.Widget> block(ReportBlock b) => [
        pw.SizedBox(height: 14),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          color: _band,
          child: pw.Row(
            children: [
              pw.Expanded(child: pw.Text(t(b.title), style: h2)),
              if (b.insufficient) insufficientTag(),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        for (final line in b.lines) pw.Bullet(text: t(line), style: body),
        for (final line in b.missing) pw.Bullet(text: t('${s.insufficientData}: $line'), style: missingStyle),
      ];

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(36),
    footer: (ctx) => pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
    ),
    build: (ctx) => [
      pw.Text(t(s.fullReportTitle), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Text(
        t('${s.lastNDays(report.periodDays)} · ${formatDayRange(report.from, report.to, lang)}'),
        style: const pw.TextStyle(fontSize: 10),
      ),
      pw.Text(t(s.generatedOn(formatDateTime(generated, lang))), style: const pw.TextStyle(fontSize: 9)),
      if (report.allInsufficient) ...[
        pw.SizedBox(height: 12),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          color: _warning,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(t(s.insufficientData), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(t(s.insufficientDataHelp), style: body),
            ],
          ),
        ),
      ],
      for (final b in blocks) ...block(b),
      pw.SizedBox(height: 14),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        color: _band,
        child: pw.Text(t(s.reportConclusions), style: h2),
      ),
      pw.SizedBox(height: 6),
      for (final c in conclusions) pw.Bullet(text: t(c), style: body),
      if (aiText != null && aiText.trim().isNotEmpty) ...[
        pw.SizedBox(height: 14),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          color: _band,
          child: pw.Text(t(s.aiResultTitle), style: h2),
        ),
        pw.SizedBox(height: 6),
        pw.Text(t(aiText.trim()), style: body),
        pw.SizedBox(height: 4),
        pw.Text(t(s.aiResultNotice), style: missingStyle),
      ],
      pw.SizedBox(height: 18),
      pw.Text(t(s.reportNotice), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Text(t(s.medicalDisclaimer), style: const pw.TextStyle(fontSize: 8)),
    ],
  ));
  return doc.save();
}
