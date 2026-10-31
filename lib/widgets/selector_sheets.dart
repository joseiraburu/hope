// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../state/pain_state.dart';
import '../utils/format.dart';

/// Hoja inferior para marcar las zonas afectadas.
Future<void> showZonesSheet(BuildContext context, PainState state) {
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
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(s.zonesTitle, style: Theme.of(ctx).textTheme.titleLarge),
                    ),
                    TextButton(
                      onPressed: () => state.setZones(app.config.zones.map((z) => z.id)),
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
                    s.zonesSummary(state.zones.length, formatPct(state.surfacePct, app.language)),
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final z in app.config.zones)
                      CheckboxListTile(
                        value: state.zones.contains(z.id),
                        onChanged: (_) => state.toggleZone(z.id),
                        title: Text(z.name(app.language)),
                        subtitle: Text(formatPct(z.pct, app.language)),
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
