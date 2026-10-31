// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/body_geometry.dart';
import 'pain_scene.dart';

/// Colores de la silueta según el tema claro u oscuro.
class BodyPalette {
  const BodyPalette({
    required this.fill,
    required this.outline,
    required this.border,
    required this.decor,
    required this.selectedStroke,
    required this.sparkShadow,
  });

  final Color fill;
  final Color outline;
  final Color border;
  final Color decor;
  final Color selectedStroke;
  final Color sparkShadow;

  static const light = BodyPalette(
    fill: Color(0xFFE9E4DE),
    outline: Color(0xFF8A837C),
    border: Color(0xFFFFFFFF),
    decor: Color(0xFFB8B0A8),
    selectedStroke: Color(0xFFB71C1C),
    sparkShadow: Color(0x55000000),
  );

  static const dark = BodyPalette(
    fill: Color(0xFF3A3734),
    outline: Color(0xFF8A837C),
    border: Color(0xFF242220),
    decor: Color(0xFF5E5953),
    selectedStroke: Color(0xFFFF5252),
    sparkShadow: Color(0x66000000),
  );

  static BodyPalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Transformación entre la caja de la silueta y el lienzo.
class BodyFit {
  BodyFit(Size canvas, Size viewBox)
      : scale = math.min(canvas.width / viewBox.width, canvas.height / viewBox.height),
        offset = Offset.zero {
    offset = Offset(
      (canvas.width - viewBox.width * scale) / 2,
      (canvas.height - viewBox.height * scale) / 2,
    );
  }

  final double scale;
  Offset offset;

  Offset toBody(Offset canvasPoint) => (canvasPoint - offset) / scale;
}

/// Dibuja la silueta, el dolor de fondo pulsante y las chispas.
class BodyPainter extends CustomPainter {
  BodyPainter({
    required this.geometry,
    required this.viewBox,
    required this.scene,
    required this.palette,
    required this.reducedMotion,
    this.clock,
    this.staticPhase = 0.25,
  }) : super(repaint: clock);

  final ViewGeometry geometry;
  final Size viewBox;
  final PainScene scene;
  final BodyPalette palette;
  final bool reducedMotion;

  /// Fase del bucle (0–1). Si es null se dibuja un fotograma fijo.
  final Animation<double>? clock;
  final double staticPhase;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final fit = BodyFit(size, viewBox);
    final t = (clock?.value ?? staticPhase) * scene.loopSeconds;

    canvas.save();
    canvas.translate(fit.offset.dx, fit.offset.dy);
    canvas.scale(fit.scale);

    // 1. Contorno: se dibuja todo con trazo grueso y luego se rellena encima,
    //    así solo queda visible el borde exterior de la figura.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round
      ..color = palette.outline;
    for (final p in geometry.allShapes) {
      canvas.drawPath(p, outline);
    }
    final fill = Paint()..color = palette.fill;
    for (final p in geometry.allShapes) {
      canvas.drawPath(p, fill);
    }

    // 2. Límites suaves entre zonas.
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeJoin = StrokeJoin.round
      ..color = palette.border;
    for (final p in geometry.zones.values) {
      canvas.drawPath(p, border);
    }

    // 3. Detalles (pectorales, ingles, columna).
    final decor = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..color = palette.decor;
    for (final line in geometry.decor) {
      canvas.drawPoints(ui.PointMode.polygon, line, decor);
    }

    // 4. Dolor de fondo pulsante en las zonas marcadas.
    final alpha = pulseAlpha(scene.painIntensity, t, reducedMotion);
    final base = painColor(scene.config, scene.painIntensity);
    final selFill = Paint()..color = base.withValues(alpha: alpha);
    final selStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round
      ..color = palette.selectedStroke;
    for (final z in scene.zones) {
      final p = geometry.zones[z];
      if (p == null) continue;
      if (alpha > 0) canvas.drawPath(p, selFill);
      canvas.drawPath(p, selStroke);
    }

    // 5. Chispas.
    final positions = scene.positionsFor(geometry);
    final life = SparkTiming.life(scene.eventIntensity, reducedMotion);
    final radius = 3 + 9 * scene.eventIntensity / 10;
    for (var i = 0; i < scene.sparks.length; i++) {
      final pos = positions[i];
      if (pos == null) continue;
      final spark = scene.sparks[i];
      final tau = (t - spark.start) % scene.loopSeconds;
      if (tau > life) continue;
      final a = SparkTiming.alpha(tau, scene.eventIntensity, reducedMotion);
      if (a <= 0.01) continue;
      final color = scene.config.eventTypeById[spark.type]?.color ?? Colors.white;
      paintSpark(
        canvas,
        type: spark.type,
        center: pos,
        radius: radius,
        tau: tau,
        life: life,
        alpha: a,
        angle: spark.angle,
        color: color,
        shadow: palette.sparkShadow,
        reduced: reducedMotion,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BodyPainter oldDelegate) {
    return oldDelegate.scene != scene ||
        oldDelegate.geometry != geometry ||
        oldDelegate.palette != palette ||
        oldDelegate.reducedMotion != reducedMotion ||
        oldDelegate.clock != clock ||
        oldDelegate.staticPhase != staticPhase;
  }
}

/// Dibuja una chispa del tipo indicado.
void paintSpark(
  Canvas canvas, {
  required String type,
  required Offset center,
  required double radius,
  required double tau,
  required double life,
  required double alpha,
  required double angle,
  required Color color,
  required Color shadow,
  required bool reduced,
}) {
  final r = radius;
  final dir = Offset(math.cos(angle), math.sin(angle));
  final perp = Offset(-dir.dy, dir.dx);
  final progress = (tau / life).clamp(0.0, 1.0).toDouble();
  final grow = reduced ? 1.0 : math.min(1.0, tau / 0.12);

  Paint stroke(Color c, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = c;
  Paint solid(Color c) => Paint()..color = c;

  final shadowColor = shadow.withValues(alpha: shadow.a * alpha);
  final main = color.withValues(alpha: alpha);
  final white = Colors.white.withValues(alpha: alpha);

  switch (type) {
    case 'pinchazo': {
      // Punto brillante con destello radial fino.
      for (final pass in [0, 1]) {
        final p = pass == 0 ? stroke(shadowColor, 1.6) : stroke(main, 0.7);
        for (var k = 0; k < 6; k++) {
          final a = angle + k * math.pi / 3;
          final d = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(center + d * (0.35 * r), center + d * (r * grow), p);
        }
        canvas.drawCircle(center, 0.3 * r + (pass == 0 ? 0.6 : 0), solid(pass == 0 ? shadowColor : white));
      }
    }
    case 'quemazon': {
      // Halo anaranjado que parpadea como una llama.
      final flicker = reduced ? 1.0 : 1 + 0.18 * math.sin(2 * math.pi * 9 * tau + angle);
      final rr = 1.25 * r * flicker;
      final shader = ui.Gradient.radial(
        center,
        rr,
        [
          const Color(0xFFFFF8E1).withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.85),
          color.withValues(alpha: 0),
        ],
        [0.0, 0.45, 1.0],
      );
      canvas.drawCircle(center, rr * 0.55, stroke(shadowColor, 0.8));
      canvas.drawCircle(center, rr, Paint()..shader = shader);
    }
    case 'rasgadura': {
      // Trazo irregular que se abre.
      final open = reduced ? 1.0 : math.min(1.0, tau / 0.25);
      final len = 2 * r * open;
      final path = Path();
      for (var k = 0; k <= 5; k++) {
        final along = -len / 2 + len * k / 5;
        final side = (k.isEven ? 1 : -1) * 0.28 * r * open;
        final pt = center + dir * along + perp * side;
        if (k == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, stroke(shadowColor, 2.6));
      canvas.drawPath(path, stroke(main, 1.6));
      canvas.drawPath(path, stroke(white, 0.5));
    }
    case 'aranazo': {
      // Dos o tres líneas paralelas que aparecen una detrás de otra.
      for (var k = 0; k < 3; k++) {
        final pk = reduced ? 1.0 : ((tau - k * 0.05) / 0.12).clamp(0.0, 1.0).toDouble();
        if (pk <= 0) continue;
        final offset = perp * ((k - 1) * 0.38 * r);
        final a = center + offset - dir * (0.9 * r);
        final b = a + dir * (1.8 * r * pk);
        canvas.drawLine(a, b, stroke(shadowColor, 1.8));
        canvas.drawLine(a, b, stroke(main, 0.9));
      }
    }
    case 'punzada': {
      // Rayo alargado que penetra.
      final tip = center + dir * (1.5 * r * grow);
      final tail = center - dir * (0.5 * r);
      final w = perp * (0.2 * r);
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo((tail + w).dx, (tail + w).dy)
        ..lineTo((tail - w).dx, (tail - w).dy)
        ..close();
      canvas.drawPath(path, stroke(shadowColor, 1.6));
      canvas.drawPath(path, solid(main));
      canvas.drawLine(tail, tip, stroke(white, 0.4));
    }
    default: {
      // Onda circular que se expande y se desvanece.
      final ring = r * (0.3 + 1.4 * progress);
      final width = 2.2 * (1 - progress) + 0.4;
      final fade = alpha * (1 - 0.6 * progress);
      canvas.drawCircle(center, ring, stroke(shadow.withValues(alpha: shadow.a * fade), width + 1));
      canvas.drawCircle(center, ring, stroke(color.withValues(alpha: fade), width));
      canvas.drawCircle(center, ring * 0.35, solid(color.withValues(alpha: fade * 0.35)));
    }
  }
}
