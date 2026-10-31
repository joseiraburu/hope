// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.
//
// Textos de la app en español (por defecto) e inglés.
// Para añadir un idioma, añade su código a [S.supported] y una entrada con
// ese código en cada texto. Los textos que falten se muestran en español.

/// Textos de la interfaz.
class S {
  const S(this.lang);

  final String lang;

  static const supported = ['es', 'en'];

  String _t(Map<String, String> m) => m[lang] ?? m['es']!;

  // ---------------------------------------------------------------- general
  String get appName => 'HOPE';
  String get cancel => _t({'es': 'Cancelar', 'en': 'Cancel'});
  String get accept => _t({'es': 'Aceptar', 'en': 'OK'});
  String get save => _t({'es': 'Guardar', 'en': 'Save'});
  String get delete => _t({'es': 'Borrar', 'en': 'Delete'});
  String get undo => _t({'es': 'Deshacer', 'en': 'Undo'});
  String get close => _t({'es': 'Cerrar', 'en': 'Close'});
  String get all => _t({'es': 'Todas', 'en': 'All'});
  String get none => _t({'es': 'Ninguna', 'en': 'None'});
  String get female => _t({'es': 'Mujer', 'en': 'Woman'});
  String get male => _t({'es': 'Hombre', 'en': 'Man'});
  String get front => _t({'es': 'Delante', 'en': 'Front'});
  String get back => _t({'es': 'Detrás', 'en': 'Back'});
  String get settings => _t({'es': 'Ajustes', 'en': 'Settings'});
  String get about => _t({'es': 'Acerca de', 'en': 'About'});

  // ------------------------------------------------------- pantalla principal
  String get painLabel => _t({'es': 'Dolor de fondo', 'en': 'Background pain'});
  String get eventsLabel => _t({'es': 'Eventos', 'en': 'Events'});
  String get frequencyLabel => _t({'es': 'Frecuencia', 'en': 'Frequency'});
  String get zonesButton => _t({'es': 'Zonas', 'en': 'Areas'});
  String get typesButton => _t({'es': 'Tipos', 'en': 'Types'});
  String get zonesTitle => _t({'es': 'Zonas afectadas', 'en': 'Affected areas'});
  String get typesTitle => _t({'es': 'Tipo de evento', 'en': 'Event type'});
  String get increase => _t({'es': 'Subir', 'en': 'Increase'});
  String get decrease => _t({'es': 'Bajar', 'en': 'Decrease'});
  String get perMinute => _t({'es': '/min', 'en': '/min'});
  String get register => _t({'es': 'Registrar', 'en': 'Save entry'});
  String get video => _t({'es': 'Vídeo', 'en': 'Video'});
  String get history => _t({'es': 'Histórico', 'en': 'History'});
  String get registered => _t({'es': 'Registrado', 'en': 'Entry saved'});
  String get addNote => _t({'es': 'Añadir nota', 'en': 'Add note'});
  String get note => _t({'es': 'Nota', 'en': 'Note'});
  String get noteHint => _t({
        'es': 'Por ejemplo: dormí mal, cambié la medicación…',
        'en': 'For example: slept badly, changed medication…'
      });
  String get videoComingSoon => _t({
        'es': 'La exportación de vídeo llegará en la próxima versión (fase 2).',
        'en': 'Video export is coming in the next version (phase 2).'
      });
  String get tapBodyHint => _t({
        'es': 'Toca el cuerpo o pulsa «Zonas» para marcar dónde te duele',
        'en': 'Tap the body or press “Areas” to mark where it hurts'
      });
  String get editRecord => _t({'es': 'Editar registro', 'en': 'Edit entry'});
  String get backdatedRecord =>
      _t({'es': 'Registro atrasado', 'en': 'Past entry'});
  String get changeDate => _t({'es': 'Cambiar fecha', 'en': 'Change date'});
  String sexTooltip(bool isFemale) => isFemale
      ? _t({'es': 'Silueta de mujer', 'en': 'Woman silhouette'})
      : _t({'es': 'Silueta de hombre', 'en': 'Man silhouette'});
  String get typeValue => _t({'es': 'Escribe un valor', 'en': 'Type a value'});
  String rangeHint(int min, int max) =>
      _t({'es': 'Entre $min y $max', 'en': 'Between $min and $max'});

  String zonesSummary(int count, String pct) => _t({
        'es': count == 1 ? '1 zona · $pct' : '$count zonas · $pct',
        'en': count == 1 ? '1 area · $pct' : '$count areas · $pct',
      });
  String typesSummary(int count) => _t({
        'es': count == 1 ? '1 tipo' : '$count tipos',
        'en': count == 1 ? '1 type' : '$count types',
      });
  String bodySemantics(String view, String zones) => _t({
        'es': 'Silueta $view. Zonas marcadas: $zones',
        'en': '$view silhouette. Marked areas: $zones',
      });
  String get noZones => _t({'es': 'ninguna', 'en': 'none'});

  // ---------------------------------------------------------------- resumen
  String painLine(int pain, int zones, String pct) => _t({
        'es': 'Dolor $pain/10 · $zones ${zones == 1 ? 'zona' : 'zonas'} ($pct)',
        'en': 'Pain $pain/10 · $zones ${zones == 1 ? 'area' : 'areas'} ($pct)',
      });
  String eventsLine(int intensity, int freq) => _t({
        'es': 'Eventos $intensity/10 · $freq/min',
        'en': 'Events $intensity/10 · $freq/min',
      });

  // -------------------------------------------------------------- histórico
  String get historyEmpty => _t({
        'es': 'Todavía no hay registros. Pulsa «Registrar» en la pantalla principal.',
        'en': 'No entries yet. Press “Save entry” on the main screen.'
      });
  String get filterDates => _t({'es': 'Filtrar por fechas', 'en': 'Filter by date'});
  String get clearFilter => _t({'es': 'Quitar filtro', 'en': 'Clear filter'});
  String get addPastRecord =>
      _t({'es': 'Añadir registro atrasado', 'en': 'Add past entry'});
  String get edit => _t({'es': 'Editar', 'en': 'Edit'});
  String get duplicate =>
      _t({'es': 'Usar como punto de partida', 'en': 'Use as starting point'});
  String get deleteRecordQuestion =>
      _t({'es': '¿Borrar este registro?', 'en': 'Delete this entry?'});
  String get recordDeleted => _t({'es': 'Registro borrado', 'en': 'Entry deleted'});
  String get noResultsInRange => _t({
        'es': 'No hay registros en esas fechas.',
        'en': 'No entries in that date range.'
      });

  // ---------------------------------------------------------------- ajustes
  String get profile => _t({'es': 'Perfil', 'en': 'Profile'});
  String get silhouette => _t({'es': 'Silueta', 'en': 'Silhouette'});
  String get appearance => _t({'es': 'Apariencia', 'en': 'Appearance'});
  String get theme => _t({'es': 'Tema', 'en': 'Theme'});
  String get themeSystem => _t({'es': 'Sistema', 'en': 'System'});
  String get themeLight => _t({'es': 'Claro', 'en': 'Light'});
  String get themeDark => _t({'es': 'Oscuro', 'en': 'Dark'});
  String get language => _t({'es': 'Idioma', 'en': 'Language'});
  String get motion => _t({'es': 'Reducir movimiento', 'en': 'Reduce motion'});
  String get motionHelp => _t({
        'es': 'Hace el pulso más lento y quita los destellos de las chispas. '
            'Recomendado si tienes fotosensibilidad.',
        'en': 'Slows the pulse and removes spark flashes. '
            'Recommended if you are sensitive to light.'
      });
  String get yes => _t({'es': 'Sí', 'en': 'On'});
  String get no => _t({'es': 'No', 'en': 'Off'});
  String get data => _t({'es': 'Datos', 'en': 'Data'});
  String get deleteAll =>
      _t({'es': 'Borrar todos los datos', 'en': 'Delete all data'});
  String get deleteAllQuestion => _t({
        'es': 'Se borrarán todos los registros de este dispositivo. No se puede deshacer.',
        'en': 'All entries on this device will be deleted. This cannot be undone.'
      });
  String get allDeleted =>
      _t({'es': 'Se han borrado todos los datos', 'en': 'All data deleted'});
  String get dataLocal => _t({
        'es': 'Tus registros se guardan solo en este dispositivo. HOPE no usa '
            'servidores, cuentas, publicidad ni analítica.',
        'en': 'Your entries are stored only on this device. HOPE uses no '
            'servers, accounts, ads or analytics.'
      });
  String get version => _t({'es': 'Versión', 'en': 'Version'});
  String get license => _t({
        'es': 'Software libre bajo licencia GPL-3.0.',
        'en': 'Free software under the GPL-3.0 license.'
      });

  // --------------------------------------------------- bienvenida y avisos
  String get welcomeTitle =>
      _t({'es': 'Te damos la bienvenida a HOPE', 'en': 'Welcome to HOPE'});
  String get welcomeIntro => _t({
        'es': 'HOPE te ayuda a mostrar cómo es tu dolor neuropático: dónde está, '
            'cuánto duele y cómo son los pinchazos, quemazones o descargas.',
        'en': 'HOPE helps you show what your neuropathic pain is like: where it '
            'is, how strong it is and what the pricks, burning or jolts feel like.'
      });
  String get medicalDisclaimer => _t({
        'es': 'HOPE es una herramienta de registro personal. No es un producto '
            'sanitario: no diagnostica, no recomienda tratamientos y no sustituye '
            'la consulta con profesionales sanitarios.',
        'en': 'HOPE is a personal tracking tool. It is not a medical device: it '
            'does not diagnose, recommend treatments or replace healthcare '
            'professionals.'
      });
  String get photosensitivity => _t({
        'es': 'La animación incluye pulsos y pequeños destellos. Si tienes '
            'fotosensibilidad, activa «Reducir movimiento» en Ajustes.',
        'en': 'The animation includes pulses and small flashes. If you are '
            'sensitive to light, turn on “Reduce motion” in Settings.'
      });
  String get chooseSilhouette => _t({
        'es': 'Elige la silueta con la que te identificas (puedes cambiarla después):',
        'en': 'Choose the silhouette you identify with (you can change it later):'
      });
}
