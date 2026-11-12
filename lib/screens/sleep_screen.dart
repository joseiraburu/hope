// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../models/food.dart' show dayKey, dayOf, parseDayKey;
import '../models/sleep.dart';
import '../state/app_controller.dart';
import '../utils/format.dart';
import '../widgets/dialogs.dart';

/// Noches que ofrece la lista desplegable (la de hoy y las anteriores).
const int sleepNightChoices = 30;

/// «Noche del 11 nov al 12 nov», con «Hoy» o «Ayer» delante si toca.
String sleepNightLabel(AppController app, DateTime day) {
  final s = app.strings;
  final lang = app.language;
  final start = DateTime(day.year, day.month, day.day - 1);
  final text = s.nightOf(formatShortDate(start, lang), formatShortDate(day, lang));
  final today = dayOf(DateTime.now());
  if (dayKey(day) == dayKey(today)) return '${s.today} · $text';
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  if (dayKey(day) == dayKey(yesterday)) return '${s.yesterday} · $text';
  return text;
}

/// Sueño: calidad de cada noche de 1 (muy malo) a 5 (muy bueno), con o sin
/// dolor, y la lista de noches registradas.
class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key, this.initialDate});

  /// Día en que termina la noche (por defecto, hoy: la noche pasada).
  final DateTime? initialDate;

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  late DateTime _day = dayOf(widget.initialDate ?? DateTime.now());
  final TextEditingController _note = TextEditingController();
  int? _quality;
  bool? _withPain;
  bool _dirty = false;
  bool _loaded = false;

  static const _otherDate = 'otra';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _apply(_day);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Carga lo guardado para la noche que termina el día [day].
  void _apply(DateTime day) {
    final saved = AppScope.read(context).sleepFor(day);
    _day = dayOf(day);
    _quality = saved?.quality;
    _withPain = saved?.withPain;
    _note.text = saved?.note ?? '';
    _dirty = false;
  }

  void _load(DateTime day) => setState(() => _apply(day));

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final s = AppScope.read(context).strings;
    return confirmAction(context, title: s.foodUnsaved, confirmLabel: s.discard);
  }

  Future<void> _changeDay(DateTime day) async {
    if (dayKey(day) == dayKey(_day)) return;
    if (!await _confirmDiscard() || !mounted) return;
    _load(day);
  }

  Future<void> _pickOtherDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) await _changeDay(picked);
  }

  Future<void> _save() async {
    final quality = _quality;
    if (quality == null) return;
    final app = AppScope.read(context);
    final s = app.strings;
    await app.saveSleep(SleepEntry(
      date: _day,
      quality: quality,
      withPain: _withPain,
      note: _note.text,
    ));
    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s.sleepSaved)));
  }

  Future<void> _delete(SleepEntry entry) async {
    final app = AppScope.read(context);
    final s = app.strings;
    final ok = await confirmAction(
      context,
      title: s.deleteSleepQuestion,
      message: sleepNightLabel(app, entry.date),
      confirmLabel: s.delete,
    );
    if (!ok || !mounted) return;
    final removed = await app.deleteSleep(entry.date);
    if (removed == null || !mounted) return;
    if (dayKey(removed.date) == dayKey(_day)) _load(_day);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(s.sleepDeleted),
        action: SnackBarAction(
          label: s.undo,
          onPressed: () async {
            await app.restoreSleep(removed);
            if (mounted && dayKey(removed.date) == dayKey(_day) && !_dirty) _load(_day);
          },
        ),
      ));
  }

  Future<void> _onBlockedPop(bool didPop) async {
    if (didPop) return;
    if (!await _confirmDiscard() || !mounted) return;
    setState(() => _dirty = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final today = dayOf(DateTime.now());
    final days = [
      for (var i = 0; i < sleepNightChoices; i++) DateTime(today.year, today.month, today.day - i)
    ];
    final current = dayKey(_day);
    if (!days.any((d) => dayKey(d) == current)) days.add(_day);
    final saved = app.sleepFor(_day);
    final quality = _quality;

    return PopScope<Object?>(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) => _onBlockedPop(didPop),
      child: Scaffold(
        appBar: AppBar(title: Text(s.sleep)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            InputDecorator(
              decoration: InputDecoration(
                labelText: s.sleepNight,
                prefixIcon: const Icon(Icons.bedtime_outlined),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const ValueKey('sleep-night'),
                  value: current,
                  isExpanded: true,
                  items: [
                    for (final d in days)
                      DropdownMenuItem<String>(
                        value: dayKey(d),
                        child: Text(sleepNightLabel(app, d), overflow: TextOverflow.ellipsis),
                      ),
                    DropdownMenuItem<String>(
                      value: _otherDate,
                      child: Text(s.otherDate, style: TextStyle(color: theme.colorScheme.primary)),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    if (v == _otherDate) {
                      _pickOtherDate();
                    } else {
                      _changeDay(parseDayKey(v));
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(s.sleepQuality, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  for (var q = sleepQualityMin; q <= sleepQualityMax; q++)
                    ButtonSegment<int>(
                      value: q,
                      label: Text('$q'),
                      tooltip: s.sleepQualityValue(q),
                    ),
                ],
                selected: quality == null ? <int>{} : {quality},
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() {
                  _quality = v.isEmpty ? null : v.first;
                  _dirty = true;
                }),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(s.sleepQualityName(1), style: theme.textTheme.bodySmall),
                const Spacer(),
                Text(s.sleepQualityName(5), style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              quality == null ? s.chooseSleepQuality : s.sleepQualityValue(quality),
              style: quality == null
                  ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
                  : theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(s.sleepPainLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(value: true, label: Text(s.withPain)),
                  ButtonSegment<bool>(value: false, label: Text(s.withoutPain)),
                ],
                selected: _withPain == null ? <bool>{} : {_withPain!},
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() {
                  _withPain = v.isEmpty ? null : v.first;
                  _dirty = true;
                }),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _note,
              maxLength: 300,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: s.note,
                hintText: s.sleepNoteHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (!_dirty) setState(() => _dirty = true);
              },
            ),
            const SizedBox(height: 12),
            if (saved != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: theme.colorScheme.outline),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.sleepExists, style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
            FilledButton.icon(
              onPressed: quality == null ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(s.save),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 32),
            Text(s.recentNights, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (app.sleepEntries.isEmpty)
              Text(s.sleepEmpty, style: theme.textTheme.bodyMedium)
            else
              for (final e in app.sleepEntries.take(sleepNightChoices))
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${e.quality}')),
                    title: Text(sleepNightLabel(app, e.date)),
                    subtitle: Text([
                      s.sleepQualityName(e.quality),
                      if (e.withPain == true) s.withPain,
                      if (e.withPain == false) s.withoutPain,
                      if (e.note.isNotEmpty) e.note,
                    ].join(' · ')),
                    trailing: IconButton(
                      tooltip: s.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(e),
                    ),
                    onTap: () => _changeDay(e.date),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
