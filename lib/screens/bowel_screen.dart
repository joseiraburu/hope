// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../models/bowel.dart';
import '../models/food.dart' show dayKey, dayOf;
import '../state/app_controller.dart';
import '../utils/format.dart';
import '../widgets/bowel_style.dart';
import '../widgets/dialogs.dart';
import '../widgets/home_action.dart';

/// Días que muestra la lista de la propia sección (el resto está en
/// Historial → Deposiciones).
const int bowelRecentDays = 30;

/// «Hoy · sáb 22 nov 2026», «Ayer · …» o solo la fecha.
String bowelDayLabel(AppController app, DateTime day) {
  final s = app.strings;
  final text = formatDayLong(day, app.language);
  final today = dayOf(DateTime.now());
  if (dayKey(day) == dayKey(today)) return '${s.today} · $text';
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  if (dayKey(day) == dayKey(yesterday)) return '${s.yesterday} · $text';
  return text;
}

/// Deposiciones: cada una con su fecha y hora y su calidad de 1
/// (estreñimiento total) a 5 (diarrea líquida), con una nota opcional, y la
/// lista de las de los últimos días.
class BowelScreen extends StatefulWidget {
  const BowelScreen({super.key, this.editing});

  /// Deposición que se abre para editarla (desde el Historial). Al guardar,
  /// la pantalla se cierra.
  final BowelEntry? editing;

  @override
  State<BowelScreen> createState() => _BowelScreenState();
}

class _BowelScreenState extends State<BowelScreen> {
  final TextEditingController _note = TextEditingController();

  /// Deposición que se está editando (null = una nueva).
  BowelEntry? _editing;

  /// Fecha y hora elegidas. Mientras no se toquen, se guarda la hora actual.
  DateTime _when = DateTime.now();
  bool _whenChosen = false;
  int? _quality;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) _apply(editing);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _apply(BowelEntry? entry) {
    _editing = entry;
    _when = entry?.dateTime ?? DateTime.now();
    _whenChosen = entry != null;
    _quality = entry?.quality;
    _note.text = entry?.note ?? '';
    _dirty = false;
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final s = AppScope.read(context).strings;
    return confirmAction(context, title: s.foodUnsaved, confirmLabel: s.discard);
  }

  Future<void> _edit(BowelEntry entry) async {
    if (_editing?.id == entry.id) return;
    if (!await _confirmDiscard() || !mounted) return;
    setState(() => _apply(entry));
  }

  Future<void> _startNew() async {
    if (!await _confirmDiscard() || !mounted) return;
    setState(() => _apply(null));
  }

  Future<void> _pickWhen() async {
    final initial = _whenChosen ? _when : DateTime.now();
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (!mounted) return;
    setState(() {
      _when = DateTime(d.year, d.month, d.day, t?.hour ?? initial.hour, t?.minute ?? initial.minute);
      _whenChosen = true;
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final quality = _quality;
    if (quality == null) return;
    final app = AppScope.read(context);
    final s = app.strings;
    final when = _whenChosen ? _when : DateTime.now();
    final editing = _editing;
    final entry = editing == null
        ? BowelEntry.create(dateTime: when, quality: quality, note: _note.text)
        : editing.copyWith(dateTime: when, quality: quality, note: _note.text);
    await app.saveBowel(entry);
    if (!mounted) return;
    setState(() => _apply(null));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(editing == null ? s.bowelSaved : s.bowelUpdated)));
    // Abierta desde el Historial para editar una deposición: se vuelve allí.
    if (widget.editing != null) Navigator.of(context).pop();
  }

  Future<void> _delete(BowelEntry entry) async {
    final app = AppScope.read(context);
    final s = app.strings;
    final ok = await confirmAction(
      context,
      title: s.deleteBowelQuestion,
      message: '${formatDateTime(entry.dateTime, app.language)} · ${s.bowelQualityValue(entry.quality)}',
      confirmLabel: s.delete,
    );
    if (!ok || !mounted) return;
    final removed = await app.deleteBowel(entry.id);
    if (removed == null || !mounted) return;
    if (_editing?.id == removed.id) setState(() => _apply(null));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(s.bowelDeleted),
        action: SnackBarAction(label: s.undo, onPressed: () => app.restoreBowel(removed)),
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
    final lang = app.language;
    final theme = Theme.of(context);
    final quality = _quality;
    final editing = _editing;

    // Deposiciones de los últimos días, agrupadas por día.
    final today = dayOf(DateTime.now());
    final since = DateTime(today.year, today.month, today.day - (bowelRecentDays - 1));
    final recent = [for (final e in app.bowelEntries) if (!e.dateTime.isBefore(since)) e];
    final older = app.bowelEntries.length - recent.length;
    final byDay = <String, List<BowelEntry>>{};
    for (final e in recent) {
      byDay.putIfAbsent(e.dayKeyText, () => []).add(e);
    }

    return PopScope<Object?>(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) => _onBlockedPop(didPop),
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.bowel),
          actions: const [HomeAction()],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (editing != null)
                  Card(
                    color: theme.colorScheme.secondaryContainer,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(s.bowelEditing(formatDateTime(editing.dateTime, lang))),
                      trailing: TextButton(onPressed: _startNew, child: Text(s.bowelNew)),
                    ),
                  ),
                Text(s.bowelWhen, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    key: const ValueKey('bowel-when'),
                    avatar: const Icon(Icons.schedule, size: 18),
                    label: Text(_whenChosen
                        ? formatDateTime(_when, lang)
                        : '${s.now} · ${formatTime(DateTime.now())}'),
                    tooltip: s.changeDate,
                    onPressed: _pickWhen,
                  ),
                ),
                const SizedBox(height: 20),
                Text(s.bowelQuality, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(s.bowelScaleHelp, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                for (var q = bowelQualityMin; q <= bowelQualityMax; q++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _QualityOption(
                      quality: q,
                      label: s.bowelQualityName(q),
                      selected: quality == q,
                      onTap: () => setState(() {
                        _quality = q;
                        _dirty = true;
                      }),
                    ),
                  ),
                const SizedBox(height: 14),
                TextField(
                  controller: _note,
                  maxLength: 300,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: s.note,
                    hintText: s.bowelNoteHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    if (!_dirty) setState(() => _dirty = true);
                  },
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const ValueKey('bowel-save'),
                  onPressed: quality == null ? null : _save,
                  icon: const Icon(Icons.check),
                  label: Text(quality == null ? s.chooseBowelQuality : s.save),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
                const SizedBox(height: 32),
                Text(s.recentBowel(bowelRecentDays), style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (app.bowelEntries.isEmpty)
                  Text(s.bowelEmpty, style: theme.textTheme.bodyMedium)
                else if (recent.isEmpty)
                  Text(s.bowelNoneRecent(bowelRecentDays), style: theme.textTheme.bodyMedium),
                for (final entry in byDay.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                    child: Text(
                      '${bowelDayLabel(app, entry.value.first.day)} · ${s.bowelCount(entry.value.length)}',
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                  for (final e in entry.value)
                    Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: BowelQualityBadge(quality: e.quality),
                        title: Text('${formatTime(e.dateTime)} · ${s.bowelQualityName(e.quality)}'),
                        subtitle: e.note.isEmpty ? null : Text(e.note),
                        selected: editing?.id == e.id,
                        trailing: IconButton(
                          tooltip: s.delete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(e),
                        ),
                        onTap: () => _edit(e),
                      ),
                    ),
                ],
                if (older > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(s.bowelOlderInHistory, style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Una calidad de la escala, que se elige con un solo toque.
class _QualityOption extends StatelessWidget {
  const _QualityOption({
    required this.quality,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int quality;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = bowelQualityColor(quality);
    return Semantics(
      button: true,
      selected: selected,
      label: '$quality · $label',
      excludeSemantics: true,
      child: Material(
        key: ValueKey('bowel-quality-$quality'),
        color: selected ? color.withValues(alpha: 0.16) : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? color : scheme.outlineVariant, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  BowelQualityBadge(quality: quality, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (selected) Icon(Icons.check_circle, color: color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
