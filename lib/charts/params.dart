// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import '../core/frequency_scale.dart';
import '../l10n/strings.dart';
import '../models/pain_record.dart';
import '../utils/format.dart';

/// Los cuatro parámetros de cada registro.
enum Param { pain, surface, eventIntensity, eventFrequency }

/// Valor real de un parámetro en un registro.
///
/// La frecuencia no tiene sentido cuando no hay eventos (intensidad 0 o sin
/// tipos): en ese caso se devuelve null y no cuenta en las medias.
double? paramValue(Param p, PainRecord r) => switch (p) {
      Param.pain => r.painIntensity.toDouble(),
      Param.surface => r.surfacePct,
      Param.eventIntensity => r.eventIntensity.toDouble(),
      Param.eventFrequency =>
        r.eventIntensity > 0 && r.eventTypes.isNotEmpty ? r.eventFrequency.toDouble() : null,
    };

/// Nombre del parámetro en una línea.
String paramName(Param p, S s) => switch (p) {
      Param.pain => s.seriesPain,
      Param.surface => s.seriesSurface,
      Param.eventIntensity => s.seriesEventIntensity,
      Param.eventFrequency => s.seriesEventFrequency,
    };

/// Valor con su unidad: «6,2/10», «18 %», «140/min».
String formatParam(Param p, double v, String lang) => switch (p) {
      Param.pain || Param.eventIntensity => '${formatNumber(v, lang)}/10',
      Param.surface => formatPct(v, lang),
      Param.eventFrequency => '${v.round()}/min',
    };

/// Diferencia con su unidad: «−1,5», «+3 %», «−20/min».
String formatParamChange(Param p, double delta, String lang) => switch (p) {
      Param.pain || Param.eventIntensity => formatSigned(delta, lang),
      Param.surface => '${formatSigned(delta, lang)}${lang == 'en' ? '%' : ' %'}',
      Param.eventFrequency => '${formatSigned(delta, lang, decimals: 0)}/min',
    };

/// Valor relativo (0–1) en la escala común de la gráfica.
double relativeValue(Param p, double v, FrequencyScale scale) {
  final r = switch (p) {
    Param.pain || Param.eventIntensity => v / 10,
    Param.surface => v / 100,
    Param.eventFrequency => scale.toPosition(v.round()),
  };
  return r.clamp(0.0, 1.0).toDouble();
}
