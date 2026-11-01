// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'dialogs.dart';

/// Barra vertical grande con botones + / − y valor editable.
///
/// Se puede usar arrastrando, con los botones, con el teclado (flechas) o
/// tocando el número para escribirlo.
class VerticalControl extends StatelessWidget {
  const VerticalControl({
    super.key,
    required this.label,
    required this.valueText,
    required this.position,
    required this.onPosition,
    required this.onIncrement,
    required this.onDecrement,
    required this.onTypedValue,
    required this.minValue,
    required this.maxValue,
    this.divisions,
    this.color,
    this.width = 72,
  });

  final String label;
  final String valueText;

  /// Posición de la barra (0–1).
  final double position;
  final ValueChanged<double> onPosition;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<int> onTypedValue;
  final int minValue;
  final int maxValue;
  final int? divisions;
  final Color? color;
  final double width;

  /// Etiqueta en una sola línea (para el lector de pantalla y los diálogos).
  String get plainLabel => label.replaceAll('\n', ' ');

  Future<void> _askValue(BuildContext context) async {
    final s = AppScope.read(context).strings;
    final text = await askText(
      context,
      title: plainLabel,
      hint: s.typeValue,
      helper: s.rangeHint(minValue, maxValue),
      numeric: true,
    );
    final value = int.tryParse(text ?? '');
    if (value != null) onTypedValue(value);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).strings;
    final theme = Theme.of(context);
    final active = color ?? theme.colorScheme.primary;
    return SizedBox(
      width: width,
      child: Column(
        children: [
          // La etiqueta va en dos líneas («Eventos» / «Intensidad») y se
          // reduce si no cabe, para que nunca se corte.
          SizedBox(
            height: 36,
            width: width,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(height: 1.2),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: '$plainLabel: $valueText',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _askValue(context),
              child: SizedBox(
                height: 36,
                width: width,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    valueText,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrement,
            tooltip: '${s.increase} · $plainLabel',
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 10,
                  activeTrackColor: active,
                  thumbColor: active,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                ),
                child: Slider(
                  value: position.clamp(0.0, 1.0).toDouble(),
                  divisions: divisions,
                  onChanged: onPosition,
                  semanticFormatterCallback: (_) => '$plainLabel: $valueText',
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onDecrement,
            tooltip: '${s.decrease} · $plainLabel',
            icon: const Icon(Icons.remove),
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ),
    );
  }
}
