// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../charts/full_report.dart';
import '../charts/full_report_text.dart';
import '../export/report_pdf.dart';
import '../export/share_service.dart';
import '../services/ai_analysis.dart';
import '../state/app_controller.dart';
import '../utils/format.dart';
import 'ai_settings_screen.dart';

/// Informe completo: evolución del dolor en 7, 14 o 30 días y su relación
/// con el sueño y la alimentación, con «Datos insuficientes» donde falten
/// registros. Describe; no diagnostica ni recomienda.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.initialDays = 14, this.now});

  /// Días del periodo al abrir (7, 14 o 30).
  final int initialDays;

  /// «Hoy» (para las pruebas).
  final DateTime? now;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late int _days = reportPeriods.contains(widget.initialDays) ? widget.initialDays : 14;
  String? _aiText;
  String? _aiError;
  bool _aiBusy = false;

  /// Periodo para el que se pidió el análisis con IA.
  int? _aiDays;

  ReportWriter _writer(AppController app) => ReportWriter(
        report: buildFullReport(
          records: app.records,
          foodDays: app.foodDays,
          sleep: app.sleepEntries,
          config: app.config,
          periodDays: _days,
          now: widget.now,
        ),
        s: app.strings,
        lang: app.language,
        config: app.config,
        foodName: app.foodName,
      );

  Future<void> _askAi() async {
    final app = AppScope.read(context);
    final s = app.strings;
    final settings = app.settings;
    final config = AiConfig(
      endpoint: settings.aiEndpoint,
      model: settings.aiModel,
      apiKey: settings.aiKey,
    );
    if (!config.isComplete) {
      setState(() => _aiError = s.aiNotConfigured);
      return;
    }
    final days = _days;
    final summary = _writer(app).aiSummary();
    setState(() {
      _aiBusy = true;
      _aiError = null;
      _aiText = null;
    });
    try {
      final text = await requestAiAnalysis(config, system: s.aiSystemPrompt, user: summary);
      if (!mounted || days != _days) return;
      setState(() {
        _aiText = text;
        _aiDays = days;
      });
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() => _aiError = '${s.aiFailed} (${e.message})');
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  Future<void> _exportPdf() async {
    final app = AppScope.read(context);
    final s = app.strings;
    if (!await confirmHealthDataShare(context) || !mounted) return;
    final writer = _writer(app);
    final bytes = await fullReportPdf(
      report: writer.report,
      blocks: writer.blocks(),
      conclusions: writer.conclusions(),
      s: s,
      lang: app.language,
      aiText: _aiDays == _days ? _aiText : null,
    );
    final file = await writeExportFile('HOPE_informe_${isoDate(DateTime.now())}.pdf', bytes);
    if (!mounted) return;
    await deliverFile(context, file, mimeType: 'application/pdf', subject: s.fullReportTitle);
  }

  void _openAiSettings() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AiSettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final writer = _writer(app);
    final report = writer.report;
    final blocks = writer.blocks();
    final conclusions = writer.conclusions();
    final aiText = _aiDays == _days ? _aiText : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.fullReport),
        actions: [
          IconButton(
            tooltip: s.reportExportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: [
                for (final d in reportPeriods) ButtonSegment<int>(value: d, label: Text(s.days(d))),
              ],
              selected: {_days},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _days = v.first),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${s.lastNDays(report.periodDays)} · ${formatDayRange(report.from, report.to, app.language)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (report.allInsufficient) ...[
            _InsufficientBanner(blocks: blocks),
            const SizedBox(height: 12),
          ],
          for (final b in blocks) ...[
            _BlockCard(block: b),
            const SizedBox(height: 12),
          ],
          _TextCard(
            title: s.reportConclusions,
            icon: Icons.summarize_outlined,
            children: [for (final c in conclusions) _Bullet(c)],
          ),
          const SizedBox(height: 12),
          _TextCard(
            title: s.aiResultTitle,
            icon: Icons.smart_toy_outlined,
            children: [
              if (!app.settings.aiEnabled) ...[
                Text(s.aiOffInReport, style: theme.textTheme.bodyMedium),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: _openAiSettings, child: Text(s.aiOptional)),
                ),
              ] else if (_aiBusy)
                Row(
                  children: [
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s.aiWorking)),
                  ],
                )
              else ...[
                if (aiText != null) ...[
                  SelectableText(aiText, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(s.aiResultNotice, style: theme.textTheme.bodySmall),
                ],
                if (_aiError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_aiError!, style: TextStyle(color: theme.colorScheme.error)),
                  ),
                if (aiText == null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: _askAi,
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: Text(s.aiAsk),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Text(
            s.reportNotice,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(s.medicalDisclaimer, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(s.reportExportPdf),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );
  }
}

/// Aviso grande cuando ningún apartado tiene datos suficientes.
class _InsufficientBanner extends StatelessWidget {
  const _InsufficientBanner({required this.blocks});

  final List<ReportBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).strings;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_empty, color: scheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.insufficientData,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.insufficientDataHelp, style: TextStyle(color: scheme.onTertiaryContainer)),
          const SizedBox(height: 6),
          for (final b in blocks)
            for (final m in b.missing)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $m', style: TextStyle(color: scheme.onTertiaryContainer)),
              ),
        ],
      ),
    );
  }
}

/// Un apartado del informe.
class _BlockCard extends StatelessWidget {
  const _BlockCard({required this.block});

  final ReportBlock block;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).strings;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(block.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (block.insufficient)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.insufficientData,
                      style: theme.textTheme.labelMedium?.copyWith(color: scheme.onTertiaryContainer),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (final line in block.lines) _Bullet(line),
            for (final line in block.missing)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: scheme.outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line,
                        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta con título e icono.
class _TextCard extends StatelessWidget {
  const _TextCard({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Línea con viñeta.
class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: theme.textTheme.bodyMedium),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
