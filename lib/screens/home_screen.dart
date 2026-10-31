// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animation/pain_scene.dart';
import '../core/body_geometry.dart';
import '../core/config.dart';
import '../core/frequency_scale.dart';
import '../models/pain_record.dart';
import '../state/app_controller.dart';
import '../state/pain_state.dart';
import '../utils/format.dart';
import '../widgets/body_figure.dart';
import '../widgets/dialogs.dart';
import '../widgets/logo.dart';
import '../widgets/selector_sheets.dart';
import '../widgets/vertical_control.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// Pantalla principal: silueta animada y los cuatro controles.
///
/// También sirve como editor de un registro existente ([editing]) o para
/// añadir un registro atrasado ([backdatedAt]).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.editing, this.backdatedAt});

  final PainRecord? editing;
  final DateTime? backdatedAt;

  bool get isEditor => editing != null || backdatedAt != null;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  AnimationController? _clock;
  PainState? _state;
  late PainScene _scene;
  BodyView _view = BodyView.front;
  DateTime _date = DateTime.now();
  Sex _editorSex = Sex.female;
  bool _welcomeShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state != null) return;
    final app = AppScope.read(context);
    _clock = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (app.config.loopSeconds * 1000).round()),
    )..repeat();

    final editing = widget.editing;
    final source = editing ?? (widget.isEditor ? null : app.latest);
    final state = source == null
        ? PainState(config: app.config)
        : PainState.fromRecord(app.config, source);
    if (widget.isEditor && source == null) {
      // Registro atrasado: parte del último estado conocido, si lo hay.
      final latest = app.latest;
      if (latest != null) state.loadFrom(latest);
    }
    _date = editing?.dateTime ?? widget.backdatedAt ?? DateTime.now();
    _editorSex = editing != null ? sexFromString(editing.sex) : app.sex;
    state.addListener(_onStateChanged);
    _state = state;
    _scene = state.toScene();

    if (!widget.isEditor && !app.settings.firstRunDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcome());
    }
  }

  @override
  void dispose() {
    _state?.removeListener(_onStateChanged);
    _state?.dispose();
    _clock?.dispose();
    super.dispose();
  }

  void _onStateChanged() => setState(() => _scene = _state!.toScene());

  // ---------------------------------------------------------------- acciones
  Future<void> _register() async {
    final app = AppScope.read(context);
    final s = app.strings;
    final state = _state!;
    if (widget.isEditor) {
      final record = state.toRecord(
        sex: sexToString(_editorSex),
        dateTime: _date,
        existing: widget.editing,
      );
      if (widget.editing != null) {
        await app.updateRecord(record);
      } else {
        await app.addRecord(record);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
    final record = state.toRecord(sex: app.settings.sex, dateTime: DateTime.now());
    await app.addRecord(record);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(s.registered),
      action: SnackBarAction(
        label: s.addNote,
        onPressed: () => editRecordNote(context, record),
      ),
    ));
  }

  void _exportVideo() {
    final s = AppScope.read(context).strings;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s.videoComingSoon)));
  }

  Future<void> _openHistory() async {
    final chosen = await Navigator.of(context).push<PainRecord>(
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
    if (chosen != null && mounted) _state!.loadFrom(chosen);
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (!mounted) return;
    setState(() {
      _date = DateTime(d.year, d.month, d.day, t?.hour ?? _date.hour, t?.minute ?? _date.minute);
    });
  }

  void _setSex(Sex sex) {
    if (widget.isEditor) {
      setState(() => _editorSex = sex);
      return;
    }
    final app = AppScope.read(context);
    app.updateSettings(app.settings.copyWith(sex: sexToString(sex)));
  }

  Future<void> _showWelcome() async {
    if (!mounted || _welcomeShown) return;
    _welcomeShown = true;
    final app = AppScope.read(context);
    final s = app.strings;
    final chosen = await showDialog<Sex>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const HopeLogo(size: 56),
        title: Text(s.welcomeTitle, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.welcomeIntro),
              const SizedBox(height: 12),
              Text(s.medicalDisclaimer,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(s.photosensitivity),
              const SizedBox(height: 16),
              Text(s.chooseSilhouette),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(ctx).pop(Sex.female),
            icon: const Icon(Icons.female),
            label: Text(s.female),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(ctx).pop(Sex.male),
            icon: const Icon(Icons.male),
            label: Text(s.male),
          ),
        ],
      ),
    );
    await app.updateSettings(app.settings.copyWith(
      sex: sexToString(chosen ?? Sex.female),
      firstRunDone: true,
    ));
  }

  static int _stepFrequency(int f, int direction) {
    final step = f < 50 ? 5 : (f < 100 ? 10 : 25);
    return f + direction * step;
  }

  // ------------------------------------------------------------------ vista
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final sex = widget.isEditor ? _editorSex : app.sex;
    return Scaffold(
      body: SafeArea(
        child: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.keyR): () => _register(),
            const SingleActivator(LogicalKeyboardKey.keyE): _exportVideo,
            if (!widget.isEditor)
              const SingleActivator(LogicalKeyboardKey.keyH): () => _openHistory(),
          },
          child: Focus(
            autofocus: true,
            child: LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 840;
              final content = Column(
                children: [
                  _buildHeader(context, sex),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLeft(context, wide),
                          const SizedBox(width: 6),
                          Expanded(child: _buildCenter(context, wide, sex)),
                          const SizedBox(width: 6),
                          _buildRight(context, wide),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(context),
                ],
              );
              if (constraints.maxHeight < 520) {
                return SingleChildScrollView(child: SizedBox(height: 520, child: content));
              }
              return content;
            }),
          ),
        ),
      ),
    );
  }

  Widget _sexToggle(BuildContext context, Sex sex) {
    final s = AppScope.of(context).strings;
    return SegmentedButton<Sex>(
      segments: [
        ButtonSegment(
          value: Sex.female,
          icon: const Icon(Icons.female),
          tooltip: s.sexTooltip(true),
        ),
        ButtonSegment(
          value: Sex.male,
          icon: const Icon(Icons.male),
          tooltip: s.sexTooltip(false),
        ),
      ],
      selected: {sex},
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      onSelectionChanged: (v) => _setSex(v.first),
    );
  }

  Widget _buildHeader(BuildContext context, Sex sex) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    if (widget.isEditor) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const BackButton(),
                Expanded(
                  child: Text(
                    widget.editing != null ? s.editRecord : s.backdatedRecord,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _sexToggle(context, sex),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: ActionChip(
                avatar: const Icon(Icons.event, size: 18),
                label: Text(formatDateTime(_date, app.language)),
                tooltip: s.changeDate,
                onPressed: _pickDate,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 4, 2),
      child: Row(
        children: [
          const HopeLogo(size: 34),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'HOPE',
              overflow: TextOverflow.fade,
              softWrap: false,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),
          const Spacer(),
          _sexToggle(context, sex),
          PopupMenuButton<String>(
            tooltip: s.settings,
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'settings') _openSettings();
              if (v == 'about') showHopeAbout(context);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'settings',
                child: ListTile(leading: const Icon(Icons.settings), title: Text(s.settings)),
              ),
              PopupMenuItem(
                value: 'about',
                child: ListTile(leading: const Icon(Icons.info_outline), title: Text(s.about)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeft(BuildContext context, bool wide) {
    final app = AppScope.of(context);
    final s = app.strings;
    final state = _state!;
    final width = wide ? 140.0 : 72.0;
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Expanded(
            child: VerticalControl(
              label: s.painLabel,
              valueText: '${state.intensity}',
              position: state.intensity / 10,
              divisions: 10,
              minValue: 0,
              maxValue: 10,
              color: painColor(app.config, math.max(state.intensity, 4)),
              width: width,
              onPosition: (p) => state.intensity = (p * 10).round(),
              onIncrement: () => state.intensity = state.intensity + 1,
              onDecrement: () => state.intensity = state.intensity - 1,
              onTypedValue: (v) => state.intensity = v,
            ),
          ),
          const SizedBox(height: 6),
          _SelectorButton(
            icon: Icons.accessibility_new,
            label: s.zonesButton,
            onPressed: () => showZonesSheet(context, state),
          ),
          const SizedBox(height: 4),
          Text(
            s.zonesSummary(state.zones.length, formatPct(state.surfacePct, app.language)),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildRight(BuildContext context, bool wide) {
    final app = AppScope.of(context);
    final s = app.strings;
    final state = _state!;
    final scale = FrequencyScale(app.config.freqMin, app.config.freqMax);
    final each = wide ? 88.0 : 64.0;
    final accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: each * 2 + 4,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VerticalControl(
                  label: s.eventsLabel,
                  valueText: '${state.eventIntensity}',
                  position: state.eventIntensity / 10,
                  divisions: 10,
                  minValue: 0,
                  maxValue: 10,
                  color: accent,
                  width: each,
                  onPosition: (p) => state.eventIntensity = (p * 10).round(),
                  onIncrement: () => state.eventIntensity = state.eventIntensity + 1,
                  onDecrement: () => state.eventIntensity = state.eventIntensity - 1,
                  onTypedValue: (v) => state.eventIntensity = v,
                ),
                const SizedBox(width: 4),
                VerticalControl(
                  label: s.frequencyLabel,
                  valueText: '${state.frequency}${s.perMinute}',
                  position: scale.toPosition(state.frequency),
                  minValue: app.config.freqMin,
                  maxValue: app.config.freqMax,
                  color: accent,
                  width: each,
                  onPosition: (p) => state.frequency = scale.fromPosition(p),
                  onIncrement: () => state.frequency = _stepFrequency(state.frequency, 1),
                  onDecrement: () => state.frequency = _stepFrequency(state.frequency, -1),
                  onTypedValue: (v) => state.frequency = v,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _SelectorButton(
            icon: Icons.flash_on,
            label: s.typesButton,
            onPressed: () => showEventTypesSheet(context, state),
          ),
          const SizedBox(height: 4),
          Text(
            s.typesSummary(state.eventTypes.length),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _figure(BuildContext context, BodyView view, Sex sex) {
    return BodyFigure(
      scene: _scene,
      sex: sex,
      view: view,
      clock: _clock,
      onZoneTap: (zone) => _state!.toggleZone(zone),
    );
  }

  Widget _buildCenter(BuildContext context, bool wide, Sex sex) {
    final app = AppScope.of(context);
    final s = app.strings;
    final theme = Theme.of(context);
    final state = _state!;

    Widget labelled(BodyView view) => Column(
          children: [
            Text(view == BodyView.front ? s.front : s.back, style: theme.textTheme.labelMedium),
            Expanded(child: _figure(context, view, sex)),
          ],
        );

    final types = app.config.orderedEventTypes(state.eventTypes);
    return Column(
      children: [
        if (!wide)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SegmentedButton<BodyView>(
                segments: [
                  ButtonSegment(value: BodyView.front, label: Text(s.front)),
                  ButtonSegment(value: BodyView.back, label: Text(s.back)),
                ],
                selected: {_view},
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                onSelectionChanged: (v) => setState(() => _view = v.first),
              ),
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: wide
                    ? Row(
                        children: [
                          Expanded(child: labelled(BodyView.front)),
                          Expanded(child: labelled(BodyView.back)),
                        ],
                      )
                    : _figure(context, _view, sex),
              ),
              if (state.zones.isEmpty)
                Positioned(
                  left: 4,
                  right: 4,
                  bottom: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Text(
                        s.tapBodyHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (state.eventIntensity > 0 && types.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 4,
              children: [
                for (final id in types)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EventTypeDot(color: app.config.eventTypeById[id]!.color, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        app.config.eventTypeById[id]!.name(app.language),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final s = AppScope.of(context).strings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: widget.isEditor
          ? _ActionButton(
              icon: Icons.check,
              label: s.save,
              primary: true,
              onPressed: () => _register(),
            )
          : Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.add_task,
                    label: s.register,
                    primary: true,
                    onPressed: () => _register(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.movie_outlined,
                    label: s.video,
                    onPressed: _exportVideo,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.history,
                    label: s.history,
                    onPressed: () => _openHistory(),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Botón compacto para abrir los selectores de zonas y tipos.
class _SelectorButton extends StatelessWidget {
  const _SelectorButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 4),
              Text(label),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón grande de la barra inferior (icono encima del texto).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = primary ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = primary ? scheme.onPrimary : scheme.onSurface;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: SizedBox(
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
