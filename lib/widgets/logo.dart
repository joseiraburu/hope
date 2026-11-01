// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

/// Proporción ancho/alto del logo (el símbolo dentro del óvalo).
const double kLogoAspect = 356 / 616;

/// Dibuja el logo de HOPE dentro de [rect] (se ajusta por la altura).
void paintHopeLogo(Canvas canvas, Rect rect, Color color) {
  // Caja original del SVG: x de -40 a 316, y de -45 a 571.
  final s = rect.height / 616;
  canvas.save();
  canvas.translate(rect.left, rect.top);
  canvas.scale(s);
  canvas.translate(40, 45);
  final p = Paint()
    ..style = PaintingStyle.stroke
    // En tamaños pequeños el trazo nunca baja de 1,6 píxeles.
    ..strokeWidth = s * 16 < 1.6 ? 1.6 / s : 16
    ..strokeCap = StrokeCap.round
    ..color = color;
  canvas.drawOval(Rect.fromCenter(center: const Offset(138, 263), width: 300, height: 560), p);
  canvas.drawLine(const Offset(72.5, 38), const Offset(72.5, 488), p);
  canvas.drawOval(Rect.fromCenter(center: const Offset(141.5, 262.5), width: 123, height: 193), p);
  canvas.drawLine(const Offset(72.5, 262.5), const Offset(138, 262.5), p);
  canvas.restore();
}

/// Logo de HOPE dibujado como vector (el símbolo rodeado por el óvalo).
class HopeLogo extends StatelessWidget {
  const HopeLogo({super.key, this.size = 32, this.color});

  /// Alto del logo en píxeles lógicos.
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: 'HOPE',
      image: true,
      child: CustomPaint(
        size: Size(size * kLogoAspect, size),
        painter: _LogoPainter(c),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => paintHopeLogo(canvas, Offset.zero & size, color);

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => oldDelegate.color != color;
}
