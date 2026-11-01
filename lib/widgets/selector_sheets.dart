// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../core/config.dart';
import '../state/app_controller.dart';
import '../state/pain_state.dart';
import '../utils/format.dart';

/// Hoja inferior para marcar las zonas afectadas.
///
/// Las zonas pares (pies, manos...) tienen dos botones, «Izquierda» y
/// «Derecha»; con los dos activos se marcan ambos lados.
Future<void> showZonesSheet(BuildContext context, PainState state) {
  final app = AppScope.read(context);
  final s = app.strings;
  final config = app.config;
  final lang = app.language;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
        child: ListenableBuilder(
          listenable: state,
          builder: (ctx, _) {
            final theme = Theme.of(ctx);
            final count = config.describeParts(state.zones, lang).length;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(s.zonesTitle, style: theme.textTheme.titleLarge),
                      ),
                      TextButton(
                        onPressed: () => state.setZones(config.allParts),
                        child: Text(s.all),
                      ),
                      TextButton(
                        onPressed: () => state.setZones(const []),
                        child: Text(s.none),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      s.zonesSummary(count, formatPct(state.surfacePct, lang)),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final z in config.zones)
                        _ZoneRow(
                          title: z.name(lang),
                          subtitle: z.paired
                              ? s.pctEachSide(formatPct(z.pct / 2, lang))
                              : formatPct(z.pct, lang),
                          trailing: z.paired
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final side in Side.values) ...[
                                      if (side == Side.der) const SizedBox(width: 6),
                                      FilterChip(
                                        label: Text(side == Side.izq ? s.leftSide : s.rightSide),
                                        tooltip: z.sideName(side, lang),
                                        selected: state.zones.contains(partId(z.id, side)),
                                        showCheckmark: false,
                                        onSelected: (_) => state.toggleZone(partId(z.id, side)),
                                      ),
                                    ],
                                  ],
                                )
                              : Checkbox(
                                  value: state.zones.contains(z.id),
                                  onChanged: (_) => state.toggleZone(z.id),
                                ),
                          onTap: z.paired ? null : () => state.toggleZone(z.id),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.textTheme.bodyLarge),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoja inferior para elegir los tipos de evento.
Future<void> showEventTypesSheet(BuildContext context, PainState state) {
  final app = AppScope.read(context);
  final s = app.strings;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
        child: ListenableBuilder(
          listenable: state,
          builder: (ctx, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(s.typesTitle, style: Theme.of(ctx).textTheme.titleLarge),
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final t in app.config.eventTypes)
                      CheckboxListTile(
                        value: state.eventTypes.contains(t.id),
                        onChanged: (_) => state.toggleEventType(t.id),
                        title: Text(t.name(app.language)),
                        secondary: EventTypeDot(color: t.color),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Punto de color con borde que identifica un tipo de evento.
class EventTypeDot extends StatelessWidget {
  const EventTypeDot({super.key, required this.color, this.size = 16});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
      ),
    );
  }
}
