// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'reminder.dart';

/// Preferencias de la app, guardadas en el dispositivo.
class AppSettings {
  const AppSettings({
    this.sex = 'female',
    this.themeMode = 'system',
    this.language = 'system',
    this.reducedMotion = 'system',
    this.firstRunDone = false,
    this.hideDateInExports = false,
    this.lastShareFormat = 'png',
    this.shareNoticeShown = false,
    this.reminders = defaultReminders,
    this.aiEnabled = false,
    this.aiEndpoint = '',
    this.aiModel = '',
    this.aiKey = '',
  });

  /// 'female' o 'male'.
  final String sex;

  /// 'system', 'light' o 'dark'.
  final String themeMode;

  /// 'system', 'es' o 'en'.
  final String language;

  /// 'system', 'on' u 'off'.
  final String reducedMotion;

  /// Si ya se mostró la bienvenida con el aviso médico.
  final bool firstRunDone;

  /// Oculta la fecha en las imágenes, GIF y vídeos que se comparten.
  final bool hideDateInExports;

  /// Último formato usado al compartir un registro: 'png', 'gif' o 'mp4'.
  final String lastShareFormat;

  /// Si ya se avisó de que se van a compartir datos de salud.
  final bool shareNoticeShown;

  /// Las cinco alarmas «Completa HOPE».
  final List<Reminder> reminders;

  /// Análisis complementario con IA en el informe completo. Solo se activa
  /// tras aceptar qué datos se envían.
  final bool aiEnabled;

  /// Dirección del servicio de IA (compatible con la API de OpenAI).
  final String aiEndpoint;

  /// Modelo que se pide al servicio.
  final String aiModel;

  /// Clave del servicio (puede quedar vacía). No se incluye en la copia de
  /// seguridad.
  final String aiKey;

  /// Algún recordatorio está activo.
  bool get anyReminderEnabled => reminders.any((r) => r.enabled);

  AppSettings copyWith({
    String? sex,
    String? themeMode,
    String? language,
    String? reducedMotion,
    bool? firstRunDone,
    bool? hideDateInExports,
    String? lastShareFormat,
    bool? shareNoticeShown,
    List<Reminder>? reminders,
    bool? aiEnabled,
    String? aiEndpoint,
    String? aiModel,
    String? aiKey,
  }) {
    return AppSettings(
      sex: sex ?? this.sex,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      firstRunDone: firstRunDone ?? this.firstRunDone,
      hideDateInExports: hideDateInExports ?? this.hideDateInExports,
      lastShareFormat: lastShareFormat ?? this.lastShareFormat,
      shareNoticeShown: shareNoticeShown ?? this.shareNoticeShown,
      reminders: reminders ?? this.reminders,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      aiEndpoint: aiEndpoint ?? this.aiEndpoint,
      aiModel: aiModel ?? this.aiModel,
      aiKey: aiKey ?? this.aiKey,
    );
  }

  /// [includeSecrets] = false deja fuera la clave del servicio de IA (para
  /// la copia de seguridad, que se puede compartir).
  Map<String, dynamic> toJson({bool includeSecrets = true}) => {
        'perfil_sexo': sex,
        'tema': themeMode,
        'idioma': language,
        'reducir_movimiento': reducedMotion,
        'bienvenida_vista': firstRunDone,
        'ocultar_fecha': hideDateInExports,
        'ultimo_formato': lastShareFormat,
        'aviso_compartir_visto': shareNoticeShown,
        'recordatorios': [for (final r in reminders) r.toJson()],
        'ia_activa': aiEnabled,
        'ia_url': aiEndpoint,
        'ia_modelo': aiModel,
        if (includeSecrets && aiKey.isNotEmpty) 'ia_clave': aiKey,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        sex: (j['perfil_sexo'] as String?) ?? 'female',
        themeMode: (j['tema'] as String?) ?? 'system',
        language: (j['idioma'] as String?) ?? 'system',
        reducedMotion: (j['reducir_movimiento'] as String?) ?? 'system',
        firstRunDone: (j['bienvenida_vista'] as bool?) ?? false,
        hideDateInExports: (j['ocultar_fecha'] as bool?) ?? false,
        lastShareFormat: (j['ultimo_formato'] as String?) ?? 'png',
        shareNoticeShown: (j['aviso_compartir_visto'] as bool?) ?? false,
        reminders: remindersFromJson(j['recordatorios']),
        aiEnabled: (j['ia_activa'] as bool?) ?? false,
        aiEndpoint: (j['ia_url'] as String?) ?? '',
        aiModel: (j['ia_modelo'] as String?) ?? '',
        aiKey: (j['ia_clave'] as String?) ?? '',
      );
}
