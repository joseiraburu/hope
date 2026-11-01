// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animation/body_painter.dart';
import '../animation/pain_scene.dart';
import '../charts/chart_painter.dart' show paintText;
import '../core/body_geometry.dart';
import '../core/config.dart';
import '../l10n/strings.dart';
import '../models/pain_record.dart';
import '../state/pain_state.dart';
import '../utils/format.dart';
import '../widgets/logo.dart';

/// Todo lo necesario para dibujar la tarjeta de un registro.
class RecordCardInput {
  RecordCardInput({
    required this.record,
    required this.config,
    required this.geometry,
    required this.s,
    required this.lang,
    this.hideDate = false,
    this.reducedMotion = false,
  }) : scene = sceneForRecord(config, record);

  final PainRecord record;
  final AppConfig config;
  final BodyGeometry geometry;
  final S s;
  final String lang;
  final bool hideDate;
  final bool reducedMotion;

  /// Escena del bucle de 10 s.
  final PainScene scene;

  /// Escena con todos los eventos de un minuto.
  late final PainScene minute = scene.oneMinute();

  double get loopSeconds => scene.loopSeconds;

  /// «HOPE_registro_2026-11-01_1424».
  String get baseName {
    final d = record.dateTime;
    String two(int n) => n.toString().padLeft(2, '0');
    return 'HOPE_registro_${isoDate(d)}_${two(d.hour)}${two(d.minute)}';
  }
}

TextStyle _style(double size, Color color, {FontWeight? weight}) =>
    TextStyle(fontSize: size, color: color, fontWeight: weight, fontFamily: 'Roboto', height: 1.25);

/// Dibuja la tarjeta de un registro: las dos vistas de la silueta, la fecha,
/// los cuatro valores, las zonas y la leyenda de eventos.
///
/// [t] es el segundo del bucle. Con [longExposure] se dibujan todos los
/// eventos de un minuto a la vez (imagen de «1 minuto»).
void paintRecordCard(
  Canvas canvas,
  Size size,
  RecordCardInput input, {
  double t = 0,
  bool longExposure = false,
}) {
  const palette = BodyPalette.light;
  const ink = Color(0xFF1A1A1A);
  const subtle = Color(0xFF6B655F);
  final s = input.s;
  final lang = input.lang;
  final r = input.record;
  final fs = size.width / 32;
  final pad = size.width * 0.05;

  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFAF8F5));

  // Cabecera: logo, nombre y fecha.
  final logoH = fs * 2.4;
  paintHopeLogo(canvas, Rect.fromLTWH(pad, pad, logoH * kLogoAspect, logoH), ink);
  final tx = pad + logoH * kLogoAspect + fs * 0.8;
  paintText(canvas, 'HOPE', Offset(tx, pad + fs * 0.05), _style(fs * 1.3, ink, weight: FontWeight.w800));
  if (!input.hideDate) {
    paintText(canvas, formatDateTime(r.dateTime, lang), Offset(tx, pad + fs * 1.55), _style(fs * 0.85, subtle));
  }

  // Pie: valores, zonas, tipos de evento y, en la imagen, el número de eventos.
  final types = input.config.orderedEventTypes(r.eventTypes);
  final hasEvents = r.eventIntensity > 0 && types.isNotEmpty;
  final zones = input.config.describeParts(r.zones, lang);
  final lines = <(String, TextStyle)>[
    (s.painLine(r.painIntensity, r.zoneCount, formatPct(r.surfacePct, lang)), _style(fs * 0.95, ink, weight: FontWeight.w700)),
    (hasEvents ? s.eventsLine(r.eventIntensity, r.eventFrequency) : '${s.eventsIntensityTitle}: 0/10',
        _style(fs * 0.95, ink, weight: FontWeight.w700)),
    if (zones.isNotEmpty) (zones.join(', '), _style(fs * 0.8, subtle)),
  ];
  final maxW = size.width - pad * 2;
  final painters = <TextPainter>[];
  var footerH = 0.0;
  for (final (text, style) in lines) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: maxW);
    painters.add(tp);
    footerH += tp.height + fs * 0.25;
  }
  final legendH = hasEvents ? fs * 1.5 : 0.0;
  final minuteH = longExposure && hasEvents ? fs * 1.4 : 0.0;
  footerH += legendH + minuteH + fs * 0.6;

  // Las dos siluetas, una junto a otra, con su rótulo.
  final top = pad + logoH + fs * 0.8;
  final bottom = size.height - pad - footerH;
  final labelH = fs * 1.2;
  final halfW = (size.width - pad * 2) / 2;
  final sex = sexFromString(r.sex);
  final scene = longExposure ? input.minute : input.scene;
  for (final (k, view) in [(0, BodyView.front), (1, BodyView.back)]) {
    final left = pad + k * halfW;
    paintText(
      canvas,
      view == BodyView.front ? s.front : s.back,
      Offset(left + halfW / 2, top),
      _style(fs * 0.8, subtle, weight: FontWeight.w600),
      anchor: Alignment.topCenter,
    );
    final rect = Rect.fromLTRB(left, top + labelH, left + halfW, bottom);
    canvas.save();
    canvas.translate(rect.left, rect.top);
    paintBody(
      canvas,
      rect.size,
      geometry: input.geometry.view(sex, view),
      viewBox: input.geometry.viewBox,
      scene: scene,
      palette: palette,
      reducedMotion: input.reducedMotion,
      t: t,
      view: view,
      letters: SideLetters(right: s.rightLetter, left: s.leftLetter),
      longExposure: longExposure,
    );
    canvas.restore();
  }

  // Pie.
  var y = bottom + fs * 0.4;
  for (final tp in painters) {
    tp.paint(canvas, Offset(pad, y));
    y += tp.height + fs * 0.25;
    tp.dispose();
  }
  if (hasEvents) {
    var x = pad;
    final legendStyle = _style(fs * 0.8, ink);
    for (final id in types) {
      final def = input.config.eventTypeById[id]!;
      final name = def.name(lang);
      final c = Offset(x + fs * 0.4, y + fs * 0.55);
      canvas.drawCircle(c, fs * 0.36, Paint()..color = def.color);
      canvas.drawCircle(
        c,
        fs * 0.36,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, fs * 0.06)
          ..color = subtle,
      );
      final w = paintText(canvas, name, Offset(x + fs * 1.0, y), legendStyle).width;
      x += fs * 1.0 + w + fs * 0.9;
    }
    y += legendH;
  }
  if (longExposure && hasEvents) {
    paintText(canvas, s.eventsInOneMinute(r.eventFrequency), Offset(pad, y),
        _style(fs * 0.85, subtle, weight: FontWeight.w600));
  }

  // Marca de agua discreta.
  final wm = fs * 1.6;
  paintHopeLogo(
    canvas,
    Rect.fromLTWH(size.width - pad - wm * kLogoAspect, size.height - pad * 0.6 - wm, wm * kLogoAspect, wm),
    ink.withValues(alpha: 0.18),
  );
}
