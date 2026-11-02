// Prueba del vídeo MP4 en un dispositivo de verdad (emulador de Android,
// simulador de iPhone o Windows), con el codificador y el decodificador del
// sistema.
//
// En la CI: bash tool/prueba_video.sh <dispositivo> [carpeta de muestras]

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope/core/body_geometry.dart';
import 'package:hope/core/config.dart';
import 'package:hope/export/record_card.dart';
import 'package:hope/export/record_export.dart';
import 'package:hope/l10n/strings.dart';
import 'package:hope/models/pain_record.dart';
import 'package:hope_media/hope_media.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// Carpeta donde dejar los vídeos para validarlos después (solo Windows).
const _outDir = String.fromEnvironment('HOPE_MUESTRAS');

Future<String> _videoPath(String name) async {
  final dir = _outDir.isNotEmpty ? Directory(_outDir) : await getTemporaryDirectory();
  dir.createSync(recursive: true);
  return '${dir.path}${Platform.pathSeparator}$name';
}

int _red(int argb) => (argb >> 16) & 0xFF;
int _green(int argb) => (argb >> 8) & 0xFF;
int _blue(int argb) => argb & 0xFF;
String _rgb(int argb) => 'rgb(${_red(argb)}, ${_green(argb)}, ${_blue(argb)})';

/// Línea que la CI convierte en una anotación.
void _report(String text) {
  // ignore: avoid_print
  print('HOPE_VIDEO: $text');
}

PainRecord _record(AppConfig config) {
  const zones = ['pies_izq', 'pies_der', 'pantorrillas_izq', 'manos_der', 'cuello_detras'];
  return PainRecord(
    id: 'video-prueba',
    dateTime: DateTime(2026, 11, 1, 14, 24),
    sex: 'female',
    painIntensity: 6,
    zones: zones,
    zoneCount: config.describeParts(zones, 'es').length,
    surfacePct: config.surfacePct(zones),
    eventIntensity: 7,
    eventTypes: const ['pinchazo', 'quemazon', 'punzada'],
    eventFrequency: 120,
    seed: 4242,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('vídeo MP4 con el codificador del sistema', (tester) async {
    final os = Platform.operatingSystem;
    final supported = await HopeMedia.isMp4Supported();
    _report('$os: codificador H.264 ${supported ? 'disponible' : 'NO disponible'}');
    if (!supported) {
      // Todos los Android e iPhone lo tienen. En Windows puede faltar Media
      // Foundation (ediciones «N», algunos servidores): la app ofrece entonces
      // el GIF.
      expect(Platform.isAndroid || Platform.isIOS, isFalse,
          reason: 'Android e iOS incluyen un codificador H.264');
      return;
    }

    // 1) Patrón: mitad de arriba roja y mitad de abajo azul. Comprueba que el
    //    vídeo no sale invertido y que los canales de color no se cruzan.
    const width = 720, height = 1280, fps = 30;
    final pattern = Uint8List(width * height * 4);
    for (var y = 0; y < height; y++) {
      final top = y < height ~/ 2;
      for (var x = 0; x < width; x++) {
        final o = (y * width + x) * 4;
        pattern[o] = top ? 230 : 20;
        pattern[o + 1] = top ? 20 : 40;
        pattern[o + 2] = top ? 20 : 230;
        pattern[o + 3] = 255;
      }
    }
    final patternPath = await _videoPath('patron_$os.mp4');
    final encoder = await HopeMedia.startMp4(path: patternPath, width: width, height: height, fps: fps);
    for (var k = 0; k < fps; k++) {
      await encoder.addFrame(pattern);
    }
    await encoder.finish();
    final p = await HopeMedia.probe(patternPath);
    expect(p, isNotNull);
    final top = p!['topColor'] as int;
    final bottom = p['bottomColor'] as int;
    _report('patrón ${p['width']}x${p['height']}, ${p['frames']} fotogramas, '
        '${p['durationMs']} ms; arriba ${_rgb(top)}, abajo ${_rgb(bottom)}');
    expect(p['width'], width);
    expect(p['height'], height);
    expect(_red(top), greaterThan(170), reason: 'arriba debe ser rojo: ${_rgb(top)}');
    expect(_blue(top), lessThan(90), reason: 'arriba debe ser rojo: ${_rgb(top)}');
    expect(_blue(bottom), greaterThan(170), reason: 'abajo debe ser azul: ${_rgb(bottom)}');
    expect(_red(bottom), lessThan(90), reason: 'abajo debe ser azul: ${_rgb(bottom)}');

    // 2) Vídeo de un registro, igual que en la app (20 s a 30 fps).
    final config = AppConfig.fromJsonString(await rootBundle.loadString('assets/config/hope_config.json'));
    final geometry =
        BodyGeometry.fromJsonString(await rootBundle.loadString('assets/config/body_geometry.json'));
    final input = RecordCardInput(
      record: _record(config),
      config: config,
      geometry: geometry,
      s: const S('es'),
      lang: 'es',
    );
    final path = await _videoPath('registro_$os.mp4');
    final watch = Stopwatch()..start();
    var progress = 0.0;
    final ok = await recordMp4(input, path, onProgress: (v) => progress = v);
    watch.stop();
    expect(ok, isTrue);
    expect(progress, 1.0);
    final info = await HopeMedia.probe(path);
    expect(info, isNotNull);
    final bytes = info!['bytes'] as int;
    _report('registro ${info['width']}x${info['height']}, ${info['frames']} fotogramas, '
        '${info['durationMs']} ms, ${(bytes / 1048576).toStringAsFixed(2)} MB, '
        'creado en ${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s; '
        'colores ${_rgb(info['topColor'] as int)} / ${_rgb(info['bottomColor'] as int)}');
    expect(info['width'], 720);
    expect(info['height'], 1280);
    expect(info['durationMs'] as int, inInclusiveRange(19700, 20300));
    final frames = info['frames'] as int?;
    if (frames != null) expect(frames, inInclusiveRange(595, 600));
    expect(bytes, lessThan(8 * 1048576));
    // El fondo de la tarjeta es claro: el fotograma no está vacío ni negro.
    int light(int argb) => _red(argb) + _green(argb) + _blue(argb);
    final a = info['topColor'] as int;
    final b = info['bottomColor'] as int;
    expect(light(a) > 600 || light(b) > 600, isTrue, reason: 'fondo ${_rgb(a)} / ${_rgb(b)}');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
