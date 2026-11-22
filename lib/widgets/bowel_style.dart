// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../models/bowel.dart';

/// Color de cada calidad de deposición: marrones para las duras, verde para
/// la normal y azules para las blandas y líquidas. El rojo se reserva para
/// el dolor. El color siempre va acompañado del número y del nombre.
Color bowelQualityColor(int quality) => switch (quality) {
      1 => const Color(0xFF5D4037),
      2 => const Color(0xFF8D6E63),
      3 => const Color(0xFF2E7D32),
      4 => const Color(0xFF00897B),
      _ => const Color(0xFF1565C0),
    };

/// Círculo con el número de la calidad, en su color.
class BowelQualityBadge extends StatelessWidget {
  const BowelQualityBadge({super.key, required this.quality, this.size = 40});

  final int quality;
  final double size;

  @override
  Widget build(BuildContext context) {
    final q = quality.clamp(bowelQualityMin, bowelQualityMax).toInt();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bowelQualityColor(q), shape: BoxShape.circle),
        child: Text(
          '$q',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.45,
          ),
        ),
      ),
    );
  }
}
