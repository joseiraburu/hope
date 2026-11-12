// Recordatorios «Completa HOPE», calendario (.ics), ajustes de la IA y su
// petición.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hope/data/backup.dart';
import 'package:hope/l10n/strings.dart';
import 'package:hope/models/app_settings.dart';
import 'package:hope/models/food.dart';
import 'package:hope/models/reminder.dart';
import 'package:hope/services/ai_analysis.dart';
import 'package:hope/services/reminders.dart';

void main() {
  const es = S('es');

  group('alarmas', () {
    test('cinco alarmas de partida, una por toma y apagadas', () {
      const settings = AppSettings();
      expect(settings.reminders.length, reminderCount);
      expect(settings.reminders.map((r) => r.slot), MealSlot.values);
      expect(settings.reminders.map((r) => r.timeText), ['08:00', '11:00', '14:00', '17:30', '21:00']);
      expect(settings.anyReminderEnabled, isFalse);
    });

    test('se guardan con los ajustes y se leen siempre cinco', () {
      final list = [...defaultReminders];
      list[0] = list[0].copyWith(enabled: true, hour: 7, minute: 45);
      list[2] = list[2].copyWith(slot: MealSlot.dinner, enabled: true);
      final settings = const AppSettings().copyWith(reminders: list);
      final back = AppSettings.fromJson(jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>);
      expect(back.reminders[0].enabled, isTrue);
      expect(back.reminders[0].timeText, '07:45');
      expect(back.reminders[2].slot, MealSlot.dinner);
      expect(back.anyReminderEnabled, isTrue);

      // Ajustes de versiones anteriores, sin alarmas, o con datos raros.
      expect(AppSettings.fromJson(const {}).reminders.length, reminderCount);
      final odd = remindersFromJson([
        {'toma': 'cena', 'activo': true, 'hora': '25:00'},
        'nada',
      ]);
      expect(odd.length, reminderCount);
      expect(odd[0].slot, MealSlot.dinner);
      expect(odd[0].timeText, '08:00');
      expect(odd[1].timeText, '11:00');
    });

    test('los próximos avisos van en orden y respetan el máximo', () {
      final list = [
        for (final r in defaultReminders) r.copyWith(enabled: r.slot != MealSlot.midMorning),
      ];
      final now = DateTime(2026, 11, 12, 12, 0);
      final next = upcomingReminders(list, now);
      expect(next.first.at, DateTime(2026, 11, 12, 14, 0));
      expect(next.first.slot, MealSlot.lunch);
      expect(next[1].at, DateTime(2026, 11, 12, 17, 30));
      expect(next[3].at, DateTime(2026, 11, 13, 8, 0));
      for (var i = 1; i < next.length; i++) {
        expect(next[i].at.isAfter(next[i - 1].at), isTrue);
      }
      expect(next.any((u) => u.slot == MealSlot.midMorning), isFalse);
      expect(next.length, lessThanOrEqualTo(maxPendingReminders));
      expect(upcomingReminders(defaultReminders, now), isEmpty);
    });

    test('cada aviso conserva su hora local en el cambio de hora', () {
      final list = [defaultReminders.first.copyWith(enabled: true)];
      final next = upcomingReminders(list, DateTime(2026, 10, 24, 9), days: 3);
      expect(next.map((u) => u.at.hour), everyElement(8));
      expect(next.map((u) => u.at.day), [25, 26, 27]);
    });

    test('el aviso lleva la toma que abre', () {
      expect(reminderPayload(MealSlot.snack), 'toma:merienda');
      expect(slotFromPayload('toma:merienda'), MealSlot.snack);
      expect(slotFromPayload('otra:cosa'), isNull);
      expect(slotFromPayload(null), isNull);
      expect(es.reminderTitle, 'Completa HOPE');
    });
  });

  group('calendario (.ics)', () {
    final list = [
      defaultReminders[0].copyWith(enabled: true),
      defaultReminders[4].copyWith(enabled: true),
    ];
    final ics = buildRemindersIcs(list, es, now: DateTime(2026, 11, 12, 10, 0));

    test('un evento diario por alarma activa', () {
      expect(ics, startsWith('BEGIN:VCALENDAR\r\n'));
      expect(ics, endsWith('END:VCALENDAR\r\n'));
      expect('BEGIN:VEVENT'.allMatches(ics).length, 2);
      expect('RRULE:FREQ=DAILY'.allMatches(ics).length, 2);
      // El desayuno de hoy ya pasó: empieza mañana. La cena, hoy.
      expect(ics, contains('DTSTART:20261113T080000'));
      expect(ics, contains('DTSTART:20261112T210000'));
      expect(ics, contains('BEGIN:VALARM'));
    });

    test('las líneas no pasan de 75 bytes y los textos se escapan', () {
      for (final line in ics.split('\r\n')) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75), reason: line);
      }
      final unfolded = ics.replaceAll('\r\n ', '');
      expect(unfolded, contains('SUMMARY:Completa HOPE · Desayuno'));
      expect(unfolded, contains('Evalúa tu dolor y registra lo que has tomado (Cena).'));
    });

    test('plegar líneas largas con tildes', () {
      final long = 'DESCRIPTION:${'á' * 60}';
      final folded = foldIcsLine(long);
      for (final line in folded.split('\r\n')) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75));
      }
      expect(folded.replaceAll('\r\n ', ''), long);
    });
  });

  group('análisis con IA', () {
    test('desactivado por defecto y la clave no va en la copia de seguridad', () {
      const settings = AppSettings();
      expect(settings.aiEnabled, isFalse);
      final withKey = settings.copyWith(
        aiEnabled: true,
        aiEndpoint: 'https://example.org/v1/chat/completions',
        aiModel: 'modelo',
        aiKey: 'secreta',
      );
      expect(withKey.toJson()['ia_clave'], 'secreta');
      final backup = encodeBackup(BackupData(
        records: const [],
        treatments: const [],
        medications: const [],
        settings: withKey,
      ));
      expect(backup, isNot(contains('secreta')));
      final back = decodeBackup(backup)!;
      expect(back.settings!.aiEnabled, isTrue);
      expect(back.settings!.aiModel, 'modelo');
      expect(back.settings!.aiKey, '');
    });

    test('configuración completa solo con dirección http(s) y modelo', () {
      expect(const AiConfig(endpoint: '', model: 'm').isComplete, isFalse);
      expect(const AiConfig(endpoint: 'https://x.org/v1/chat/completions', model: '').isComplete, isFalse);
      expect(const AiConfig(endpoint: 'ftp://x.org', model: 'm').isComplete, isFalse);
      expect(const AiConfig(endpoint: 'http://localhost:11434/v1/chat/completions', model: 'llama3.2').isComplete,
          isTrue);
    });

    test('la petición lleva las instrucciones y el resumen; la respuesta se lee', () {
      const config = AiConfig(endpoint: 'https://x.org/v1/chat/completions', model: ' m1 ');
      final body = aiRequestBody(config, 'sistema', 'resumen');
      expect(body['model'], 'm1');
      expect((body['messages'] as List).first, {'role': 'system', 'content': 'sistema'});
      expect((body['messages'] as List).last, {'role': 'user', 'content': 'resumen'});
      expect(
        parseAiResponse('{"choices":[{"message":{"role":"assistant","content":"  Texto  "}}]}'),
        'Texto',
      );
      expect(() => parseAiResponse('{"error":{"message":"clave no válida"}}'),
          throwsA(isA<AiException>().having((e) => e.message, 'message', 'clave no válida')));
      expect(() => parseAiResponse('no es json'), throwsA(isA<AiException>()));
    });

    test('sin configuración no se intenta la conexión', () async {
      await expectLater(
        requestAiAnalysis(const AiConfig(endpoint: '', model: ''), system: 's', user: 'u'),
        throwsA(isA<AiException>()),
      );
    });

    test('las instrucciones prohíben diagnosticar y recomendar', () {
      expect(es.aiSystemPrompt, contains('No diagnostiques'));
      expect(es.aiSystemPrompt, contains('no recomiendes'));
      expect(const S('en').aiSystemPrompt, contains('Do not diagnose'));
    });
  });
}
