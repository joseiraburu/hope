// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
import '../models/pain_record.dart' show newUuid;
import '../models/treatment.dart';
import '../state/app_controller.dart';
import '../utils/format.dart';
import '../widgets/dialogs.dart';

/// Crea o edita un tratamiento.
///
/// La dosis la escribe siempre el usuario: la app solo comprueba que sea un
/// número positivo y nunca la compara con rangos terapéuticos.
class TreatmentEditorScreen extends StatefulWidget {
  const TreatmentEditorScreen({super.key, this.editing, this.template});

  /// Tratamiento que se edita.
  final Treatment? editing;

  /// Tratamiento del que se parte al duplicar.
  final Treatment? template;

  @override
  State<TreatmentEditorScreen> createState() => _TreatmentEditorScreenState();
}

class _TreatmentEditorScreenState extends State<TreatmentEditorScreen> {
  static const _addMedicationValue = '__nuevo__';

  final _dose = TextEditingController();
  final _schedule = TextEditingController();
  final _notes = TextEditingController();
  final _otherEffects = TextEditingController();

  String? _medicationId;
  String _route = 'otra';
  String _unit = 'mg';
  DateTime _start = DateTime.now();
  DateTime? _end;
  final Set<String> _effects = {};
  String? _doseError;
  String? _medicationError;
  String? _endError;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final app = AppScope.read(context);
    final source = widget.editing ?? widget.template;
    if (source != null) {
      _medicationId = app.medicationById(source.medicationId) == null ? null : source.medicationId;
      _route = source.route;
      _unit = source.unit;
      _dose.text = formatNumber(source.dose, app.language, decimals: 2);
      _schedule.text = source.schedule;
      _notes.text = source.notes;
      _otherEffects.text = source.adverseOther;
      _effects.addAll(source.adverseEffects);
      if (widget.editing != null) {
        _start = source.start;
        _end = source.end;
      } else if (source.end != null) {
        // Al duplicar un periodo se conserva su duración, empezando ahora.
        _end = _start.add(source.end!.difference(source.start));
      }
    } else {
      final visible = app.visibleMedications;
      if (visible.isNotEmpty) _applyMedication(visible.first.id);
    }
  }

  @override
  void dispose() {
    _dose.dispose();
    _schedule.dispose();
    _notes.dispose();
    _otherEffects.dispose();
    super.dispose();
  }

  void _applyMedication(String id) {
    final app = AppScope.read(context);
    _medicationId = id;
    _medicationError = null;
    final presets = app.config.presentationsFor(id);
    if (presets.isNotEmpty) {
      _route = presets.first.route;
      _unit = presets.first.unit;
    }
  }

  Future<void> _addMedication() async {
    final app = AppScope.read(context);
    final name = await askText(context, title: app.strings.addMedication, label: app.strings.medicationName);
    if (name == null || name.trim().isEmpty || !mounted) return;
    final m = await app.addMedication(name);
    if (!mounted) return;
    setState(() => _applyMedication(m.id));
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (d == null || !mounted) return null;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    return DateTime(d.year, d.month, d.day, t?.hour ?? initial.hour, t?.minute ?? initial.minute);
  }

  Future<void> _save() async {
    final app = AppScope.read(context);
    final s = app.strings;
    final dose = parseDecimal(_dose.text);
    setState(() {
      _medicationError = _medicationId == null ? s.medicationRequired : null;
      _doseError = dose == null || dose <= 0 ? s.doseInvalid : null;
      _endError = _end != null && _end!.isBefore(_start) ? s.endBeforeStart : null;
    });
    if (_medicationError != null || _doseError != null || _endError != null) return;
    final medId = _medicationId!;
    final t = Treatment(
      id: widget.editing?.id ?? newUuid(),
      medicationId: medId,
      medicationName: app.medicationName(medId),
      route: _route,
      dose: dose!,
      unit: _unit,
      start: _start,
      end: _end,
      schedule: _schedule.text.trim(),
      notes: _notes.text.trim(),
      adverseEffects: [
        for (final e in app.config.adverseEffects) if (_effects.contains(e.id)) e.id
      ],
      adverseOther: _otherEffects.text.trim(),
    );
    if (widget.editing != null) {
      await app.updateTreatment(t);
    } else {
      await app.addTreatment(t);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final lang = app.language;
    final theme = Theme.of(context);
    final medications = [
      for (final m in app.medications)
        if (!m.hidden || m.id == _medicationId) m
    ];
    final List<Presentation> presets =
        _medicationId == null ? const [] : app.config.presentationsFor(_medicationId!);

    Widget dropdown({
      required String label,
      required String? value,
      required List<DropdownMenuItem<String>> items,
      required ValueChanged<String?> onChanged,
      String? errorText,
    }) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing == null ? s.addTreatment : s.editTreatment),
        actions: [
          TextButton(onPressed: _save, child: Text(s.save)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            dropdown(
              label: s.medication,
              value: _medicationId,
              errorText: _medicationError,
              items: [
                for (final m in medications)
                  DropdownMenuItem(value: m.id, child: Text(app.medicationName(m.id))),
                DropdownMenuItem(
                  value: _addMedicationValue,
                  child: Text('${s.addMedication}…', style: TextStyle(color: theme.colorScheme.primary)),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                if (v == _addMedicationValue) {
                  _addMedication();
                } else {
                  setState(() => _applyMedication(v));
                }
              },
            ),
            if (presets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(s.presets, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final p in presets)
                    ChoiceChip(
                      label: Text('${app.config.routeName(p.route, lang)} · ${app.config.unitName(p.unit, lang)}'),
                      selected: _route == p.route && _unit == p.unit,
                      onSelected: (_) => setState(() {
                        _route = p.route;
                        _unit = p.unit;
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            dropdown(
              label: s.route,
              value: app.config.routeById(_route) == null ? 'otra' : _route,
              items: [
                for (final r in app.config.routes)
                  DropdownMenuItem(value: r.id, child: Text(r.name(lang))),
              ],
              onChanged: (v) => setState(() => _route = v ?? _route),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _dose,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    decoration: InputDecoration(
                      labelText: s.dose,
                      errorText: _doseError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: dropdown(
                    label: s.unit,
                    value: app.config.unitById(_unit) == null ? 'otra' : _unit,
                    items: [
                      for (final u in app.config.units)
                        DropdownMenuItem(value: u.id, child: Text(u.name(lang))),
                    ],
                    onChanged: (v) => setState(() => _unit = v ?? _unit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DateTile(
              label: s.startDate,
              value: formatDateTime(_start, lang),
              onTap: () async {
                final d = await _pickDateTime(_start);
                if (d != null) setState(() => _start = d);
              },
            ),
            const SizedBox(height: 8),
            if (_end == null)
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.noEndDate, style: theme.textTheme.bodyMedium),
                    TextButton.icon(
                      onPressed: () async {
                        final d = await _pickDateTime(_start.add(const Duration(days: 3)));
                        if (d != null) setState(() => _end = d);
                      },
                      icon: const Icon(Icons.event),
                      label: Text(s.setEndDate),
                    ),
                  ],
                ),
              )
            else
              _DateTile(
                label: s.endDate,
                value: formatDateTime(_end!, lang),
                errorText: _endError,
                onTap: () async {
                  final d = await _pickDateTime(_end!);
                  if (d != null) setState(() => _end = d);
                },
                onClear: () => setState(() {
                  _end = null;
                  _endError = null;
                }),
                clearTooltip: s.removeEndDate,
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _schedule,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: s.schedule,
                hintText: s.scheduleHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(s.adverseEffects, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final e in app.config.adverseEffects)
                  FilterChip(
                    label: Text(e.name(lang)),
                    selected: _effects.contains(e.id),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _effects.add(e.id);
                      } else {
                        _effects.remove(e.id);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otherEffects,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: s.otherEffects,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              maxLength: 500,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: s.notes,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(s.save),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
    this.clearTooltip,
    this.errorText,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String? clearTooltip;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.event),
          suffixIcon: onClear == null
              ? null
              : IconButton(tooltip: clearTooltip, icon: const Icon(Icons.close), onPressed: onClear),
        ),
        child: Text(value),
      ),
    );
  }
}
