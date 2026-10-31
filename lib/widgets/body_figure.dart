// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../animation/body_painter.dart';
import '../animation/pain_scene.dart';
import '../core/body_geometry.dart';
import '../core/config.dart';
import '../state/app_controller.dart';

/// Silueta animada. Si [onZoneTap] no es null, tocar una zona la marca.
class BodyFigure extends StatelessWidget {
  const BodyFigure({
    super.key,
    required this.scene,
    required this.sex,
    required this.view,
    this.clock,
    this.onZoneTap,
  });

  final PainScene scene;
  final Sex sex;
  final BodyView view;
  final Animation<double>? clock;
  final ValueChanged<String>? onZoneTap;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.strings;
    final geometry = app.geometry.view(sex, view);
    final palette = BodyPalette.of(Theme.of(context).brightness);
    final reduced = app.reducedMotion(context);
    final zoneNames = scene.zones
        .map((z) => app.config.zoneById[z]?.name(app.language) ?? z)
        .join(', ');

    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final painter = CustomPaint(
        size: size,
        painter: BodyPainter(
          geometry: geometry,
          viewBox: app.geometry.viewBox,
          scene: scene,
          palette: palette,
          reducedMotion: reduced,
          clock: clock,
        ),
      );
      final tap = onZoneTap;
      return Semantics(
        label: s.bodySemantics(
          view == BodyView.front ? s.front : s.back,
          zoneNames.isEmpty ? s.noZones : zoneNames,
        ),
        child: RepaintBoundary(
          child: tap == null
              ? painter
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final fit = BodyFit(size, app.geometry.viewBox);
                    final zone = geometry.zoneAt(fit.toBody(details.localPosition));
                    if (zone != null) tap(zone);
                  },
                  child: painter,
                ),
        ),
      );
    });
  }
}
