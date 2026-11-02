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
  String get continueLabel => _t({'es': 'Continuar', 'en': 'Continue'});
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
  String get yes => _t({'es': 'Sí', 'en': 'On'});
  String get no => _t({'es': 'No', 'en': 'Off'});

  // ------------------------------------------------------- pantalla principal
  /// Etiquetas de las barras (en dos líneas).
  String get painLabel => _t({'es': 'Dolor\nde fondo', 'en': 'Background\npain'});
  String get eventsIntensityLabel => _t({'es': 'Eventos\nIntensidad', 'en': 'Events\nIntensity'});
  String get eventsFrequencyLabel => _t({'es': 'Eventos\nFrecuencia', 'en': 'Events\nFrequency'});

  /// Los mismos nombres en una línea.
  String get painTitle => _t({'es': 'Dolor de fondo', 'en': 'Background pain'});
  String get eventsIntensityTitle =>
      _t({'es': 'Eventos - intensidad', 'en': 'Events - intensity'});
  String get eventsFrequencyTitle =>
      _t({'es': 'Eventos - frecuencia', 'en': 'Events - frequency'});
  String get surfaceTitle => _t({'es': 'Superficie afectada', 'en': 'Affected surface'});

  String get zonesButton => _t({'es': 'Zonas', 'en': 'Areas'});
  String get typesButton => _t({'es': 'Tipos', 'en': 'Types'});
  String get zonesTitle => _t({'es': 'Zonas afectadas', 'en': 'Affected areas'});
  String get typesTitle => _t({'es': 'Tipo de evento', 'en': 'Event type'});
  String get leftSide => _t({'es': 'Izquierda', 'en': 'Left'});
  String get rightSide => _t({'es': 'Derecha', 'en': 'Right'});
  String get leftLetter => _t({'es': 'I', 'en': 'L'});
  String get rightLetter => _t({'es': 'D', 'en': 'R'});
  String pctEachSide(String pct) => _t({'es': '$pct cada lado', 'en': '$pct each side'});
  String get increase => _t({'es': 'Subir', 'en': 'Increase'});
  String get decrease => _t({'es': 'Bajar', 'en': 'Decrease'});
  String get perMinute => '/min';
  String get register => _t({'es': 'Registrar', 'en': 'Save entry'});
  String get share => _t({'es': 'Compartir', 'en': 'Share'});
  String get history => _t({'es': 'Histórico', 'en': 'History'});
  String get charts => _t({'es': 'Gráficos', 'en': 'Charts'});
  String get treatments => _t({'es': 'Tratamientos', 'en': 'Treatments'});
  String get registered => _t({'es': 'Registrado', 'en': 'Entry saved'});
  String get addNote => _t({'es': 'Añadir nota', 'en': 'Add note'});
  String get note => _t({'es': 'Nota', 'en': 'Note'});
  String get noteHint => _t({
        'es': 'Por ejemplo: dormí mal, cambié la medicación…',
        'en': 'For example: slept badly, changed medication…'
      });
  String get tapBodyHint => _t({
        'es': 'Toca el cuerpo o pulsa «Zonas» para marcar dónde te duele',
        'en': 'Tap the body or press “Areas” to mark where it hurts'
      });
  String get editRecord => _t({'es': 'Editar registro', 'en': 'Edit entry'});
  String get backdatedRecord => _t({'es': 'Registro atrasado', 'en': 'Past entry'});
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
        'es': 'Eventos: intensidad $intensity/10 · frecuencia $freq/min',
        'en': 'Events: intensity $intensity/10 · frequency $freq/min',
      });
  String eventsInOneMinute(int n) => _t({
        'es': n == 1 ? '1 evento en 1 minuto' : '$n eventos en 1 minuto',
        'en': n == 1 ? '1 event in 1 minute' : '$n events in 1 minute',
      });

  // -------------------------------------------------------------- histórico
  String get historyEmpty => _t({
        'es': 'Todavía no hay registros. Pulsa «Registrar» en la pantalla principal.',
        'en': 'No entries yet. Press “Save entry” on the main screen.'
      });
  String get filterDates => _t({'es': 'Filtrar por fechas', 'en': 'Filter by date'});
  String get clearFilter => _t({'es': 'Quitar filtro', 'en': 'Clear filter'});
  String get addPastRecord => _t({'es': 'Añadir registro atrasado', 'en': 'Add past entry'});
  String get edit => _t({'es': 'Editar', 'en': 'Edit'});
  String get duplicate => _t({'es': 'Usar como punto de partida', 'en': 'Use as starting point'});
  String get deleteRecordQuestion =>
      _t({'es': '¿Borrar este registro?', 'en': 'Delete this entry?'});
  String get recordDeleted => _t({'es': 'Registro borrado', 'en': 'Entry deleted'});
  String get noResultsInRange =>
      _t({'es': 'No hay registros en esas fechas.', 'en': 'No entries in that date range.'});

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
  String get sharingSection => _t({'es': 'Al compartir', 'en': 'When sharing'});
  String get hideDate => _t({
        'es': 'Ocultar la fecha en imágenes, GIF y vídeos',
        'en': 'Hide the date in images, GIFs and videos'
      });
  String get data => _t({'es': 'Datos', 'en': 'Data'});
  String get backup => _t({'es': 'Copia de seguridad', 'en': 'Backup'});
  String get backupExport => _t({'es': 'Exportar copia de seguridad', 'en': 'Export backup'});
  String get backupExportHelp => _t({
        'es': 'Guarda en un archivo todos tus registros, tratamientos, alimentación y ajustes.',
        'en': 'Saves all your entries, treatments, food log and settings to a file.'
      });
  String get backupImport => _t({'es': 'Importar copia de seguridad', 'en': 'Import backup'});
  String get backupImportQuestion => _t({
        'es': 'Los datos de la copia sustituirán a los de este dispositivo. ¿Continuar?',
        'en': 'The backup will replace the data on this device. Continue?'
      });
  String backupImported(int records, int treatments) => _t({
        'es': 'Copia importada: $records registros y $treatments tratamientos',
        'en': 'Backup imported: $records entries and $treatments treatments'
      });
  String get backupInvalid => _t({
        'es': 'Ese archivo no es una copia de seguridad de HOPE.',
        'en': 'That file is not a HOPE backup.'
      });
  String get deleteAll => _t({'es': 'Borrar todos los datos', 'en': 'Delete all data'});
  String get deleteAllQuestion => _t({
        'es': 'Se borrarán todos los registros, tratamientos y la alimentación de este '
            'dispositivo. No se puede deshacer.',
        'en': 'All entries, treatments and the food log on this device will be deleted. '
            'This cannot be undone.'
      });
  String get allDeleted => _t({'es': 'Se han borrado todos los datos', 'en': 'All data deleted'});
  String get dataLocal => _t({
        'es': 'Tus registros se guardan solo en este dispositivo. HOPE no usa '
            'servidores, cuentas, publicidad ni analítica.',
        'en': 'Your entries are stored only on this device. HOPE uses no '
            'servers, accounts, ads or analytics.'
      });
  String get version => _t({'es': 'Versión', 'en': 'Version'});
  String get license =>
      _t({'es': 'Software libre bajo licencia GPL-3.0.', 'en': 'Free software under the GPL-3.0 license.'});

  // --------------------------------------------------- bienvenida y avisos
  String get welcomeTitle => _t({'es': 'Te damos la bienvenida a HOPE', 'en': 'Welcome to HOPE'});
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
  String get causalDisclaimer => _t({
        'es': 'Los cambios observados no demuestran que un tratamiento sea la causa. '
            'Coméntalos con tu equipo médico.',
        'en': 'Observed changes do not prove that a treatment is the cause. '
            'Discuss them with your healthcare team.'
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

  // ------------------------------------------------------------- compartir
  String get shareRecordTitle => _t({'es': 'Compartir registro', 'en': 'Share entry'});
  String get formatImage => _t({'es': 'Imagen · 1 minuto de eventos', 'en': 'Image · 1 minute of events'});
  String get formatImageHelp => _t({
        'es': 'Imagen fija con todos los eventos de un minuto (PNG).',
        'en': 'Still image with all the events of one minute (PNG).'
      });
  String get formatGif => _t({'es': 'GIF animado', 'en': 'Animated GIF'});
  String get formatGifHelp =>
      _t({'es': 'La animación de 10 segundos en bucle.', 'en': 'The 10-second animation, looping.'});
  String get formatVideo => _t({'es': 'Vídeo MP4', 'en': 'MP4 video'});
  String get formatVideoHelp => _t({
        'es': 'Vídeo de 20 segundos, ideal para WhatsApp y correo.',
        'en': '20-second video, ideal for WhatsApp and email.'
      });
  String get generating => _t({'es': 'Preparando…', 'en': 'Preparing…'});
  String get exportFailed =>
      _t({'es': 'No se ha podido crear el archivo.', 'en': 'The file could not be created.'});
  String get videoFallbackToGif => _t({
        'es': 'Este dispositivo no ha podido crear el vídeo; se ha creado un GIF.',
        'en': 'This device could not create the video; a GIF was created instead.'
      });
  String get healthDataTitle =>
      _t({'es': 'Vas a compartir datos de salud', 'en': 'You are about to share health data'});
  String get healthDataBody => _t({
        'es': 'El archivo incluye información sobre tu dolor y, si los añades, tus '
            'tratamientos. Una vez enviado, HOPE ya no controla quién puede verlo.',
        'en': 'The file includes information about your pain and, if added, your '
            'treatments. Once sent, HOPE no longer controls who can see it.'
      });
  String get fileReady => _t({'es': 'Archivo listo', 'en': 'File ready'});
  String get saveAs => _t({'es': 'Guardar como…', 'en': 'Save as…'});
  String get openFolder => _t({'es': 'Abrir carpeta', 'en': 'Open folder'});
  String savedAt(String path) => _t({'es': 'Guardado en $path', 'en': 'Saved to $path'});

  // ----------------------------------------------------------- tratamientos
  String get addTreatment => _t({'es': 'Añadir tratamiento', 'en': 'Add treatment'});
  String get editTreatment => _t({'es': 'Editar tratamiento', 'en': 'Edit treatment'});
  String get medication => _t({'es': 'Medicamento', 'en': 'Medication'});
  String get medications => _t({'es': 'Medicamentos', 'en': 'Medications'});
  String get addMedication => _t({'es': 'Añadir medicamento', 'en': 'Add medication'});
  String get renameMedication => _t({'es': 'Cambiar nombre', 'en': 'Rename'});
  String get hideMedication => _t({'es': 'Ocultar', 'en': 'Hide'});
  String get showMedication => _t({'es': 'Mostrar', 'en': 'Show'});
  String get hiddenLabel => _t({'es': 'Oculto', 'en': 'Hidden'});
  String get medicationsHelp => _t({
        'es': 'Ocultar un medicamento no borra su historial; solo deja de aparecer al añadir tratamientos.',
        'en': 'Hiding a medication keeps its history; it just no longer appears when adding treatments.'
      });
  String get medicationName => _t({'es': 'Nombre del medicamento', 'en': 'Medication name'});
  String get route => _t({'es': 'Vía o presentación', 'en': 'Route or form'});
  String get dose => _t({'es': 'Dosis', 'en': 'Dose'});
  String get unit => _t({'es': 'Unidad', 'en': 'Unit'});
  String get presets => _t({'es': 'Presentaciones habituales', 'en': 'Usual forms'});
  String get startDate => _t({'es': 'Inicio', 'en': 'Start'});
  String get endDate => _t({'es': 'Fin', 'en': 'End'});
  String get noEndDate =>
      _t({'es': 'Sin fecha de fin (administración puntual)', 'en': 'No end date (single administration)'});
  String get setEndDate => _t({'es': 'Añadir fecha de fin', 'en': 'Add end date'});
  String get removeEndDate => _t({'es': 'Quitar fecha de fin', 'en': 'Remove end date'});
  String get schedule => _t({'es': 'Pauta', 'en': 'Schedule'});
  String get scheduleHint =>
      _t({'es': 'Por ejemplo: cada 72 h, 12 h sí y 12 h no', 'en': 'For example: every 72 h'});
  String get notes => _t({'es': 'Notas', 'en': 'Notes'});
  String get adverseEffects => _t({'es': 'Efectos adversos', 'en': 'Side effects'});
  String get otherEffects => _t({'es': 'Otros efectos', 'en': 'Other effects'});
  String get doseInvalid =>
      _t({'es': 'Escribe una dosis mayor que 0', 'en': 'Enter a dose greater than 0'});
  String get medicationRequired =>
      _t({'es': 'Elige o añade un medicamento', 'en': 'Choose or add a medication'});
  String get endBeforeStart => _t({
        'es': 'La fecha de fin no puede ser anterior al inicio',
        'en': 'The end date cannot be before the start'
      });
  String get noTreatments => _t({
        'es': 'Todavía no hay tratamientos. Pulsa «Añadir tratamiento».',
        'en': 'No treatments yet. Press “Add treatment”.'
      });
  String get allMedications => _t({'es': 'Todos', 'en': 'All'});
  String get deleteTreatmentQuestion =>
      _t({'es': '¿Borrar este tratamiento?', 'en': 'Delete this treatment?'});
  String get treatmentDeleted => _t({'es': 'Tratamiento borrado', 'en': 'Treatment deleted'});
  String get duplicateTreatment => _t({'es': 'Duplicar', 'en': 'Duplicate'});
  String get punctual => _t({'es': 'Puntual', 'en': 'Single'});
  String get ongoing => _t({'es': 'En curso', 'en': 'Ongoing'});
  String get compareBeforeAfter =>
      _t({'es': 'Comparar antes y después', 'en': 'Compare before and after'});
  String days(int n) => _t({'es': '$n días', 'en': '$n days'});
  String get before => _t({'es': 'Antes', 'en': 'Before'});
  String get after => _t({'es': 'Después', 'en': 'After'});
  String get change => _t({'es': 'Cambio', 'en': 'Change'});
  String get parameter => _t({'es': 'Parámetro', 'en': 'Parameter'});
  String nRecords(int n) => _t({
        'es': n == 1 ? '1 registro' : '$n registros',
        'en': n == 1 ? '1 entry' : '$n entries',
      });
  String get noData => _t({'es': 'Sin datos', 'en': 'No data'});
  String compareWindow(int n) => _t({
        'es': 'Media de los $n días anteriores y de los $n días posteriores al inicio.',
        'en': 'Average of the $n days before and the $n days after the start.',
      });

  // ----------------------------------------------------------- alimentación
  String get food => _t({'es': 'Alimentación', 'en': 'Food'});
  String get foodLogTab => _t({'es': 'Registrar', 'en': 'Log'});
  String get foodHistoryTab => _t({'es': 'Historial', 'en': 'History'});
  String get foodDay => _t({'es': 'Día', 'en': 'Day'});
  String get today => _t({'es': 'Hoy', 'en': 'Today'});
  String get yesterday => _t({'es': 'Ayer', 'en': 'Yesterday'});
  String get otherDate => _t({'es': 'Elegir otra fecha…', 'en': 'Choose another date…'});
  String get morning => _t({'es': 'Mañana', 'en': 'Morning'});
  String get afternoon => _t({'es': 'Tarde', 'en': 'Afternoon'});
  String get chooseFoods => _t({'es': 'Toca para elegir alimentos', 'en': 'Tap to choose foods'});
  String get addFood => _t({'es': 'Añadir alimento…', 'en': 'Add food…'});
  String get addFoodTitle => _t({'es': 'Añadir alimento', 'en': 'Add food'});
  String get foodName => _t({'es': 'Nombre del alimento', 'en': 'Food name'});
  String foodDuplicate(String name) => _t({
        'es': 'Ese alimento ya existe: se ha marcado «$name».',
        'en': 'That food already exists: “$name” has been selected.'
      });
  String foodAdded(String name) => _t({
        'es': '«$name» se ha añadido a la lista.',
        'en': '“$name” has been added to the list.'
      });
  String get foodNameTaken =>
      _t({'es': 'Ya hay un alimento con ese nombre.', 'en': 'There is already a food with that name.'});
  String get searchFood => _t({'es': 'Buscar alimento', 'en': 'Search food'});
  String get removeFood => _t({'es': 'Quitar', 'en': 'Remove'});
  String get done => _t({'es': 'Listo', 'en': 'Done'});
  String get foodSaved => _t({'es': 'Guardado', 'en': 'Saved'});
  String get foodUnsaved => _t({
        'es': 'Tienes cambios sin guardar. ¿Descartarlos?',
        'en': 'You have unsaved changes. Discard them?'
      });
  String get discard => _t({'es': 'Descartar', 'en': 'Discard'});
  String get foodDayExists => _t({
        'es': 'Este día ya tiene comidas guardadas: al guardar se actualizan.',
        'en': 'This day already has saved meals: saving updates them.'
      });
  String get foodEmpty =>
      _t({'es': 'Aún no has registrado comidas.', 'en': "You haven't logged any meals yet."});
  String get foodLogNow => _t({'es': 'Registrar comidas', 'en': 'Log meals'});
  String get filterByFood => _t({'es': 'Filtrar por alimento', 'en': 'Filter by food'});
  String get noDaysWithFood =>
      _t({'es': 'Ningún día con ese alimento.', 'en': 'No days with that food.'});
  String foodCount(int n) => _t({
        'es': n == 1 ? '1 alimento' : '$n alimentos',
        'en': n == 1 ? '1 food' : '$n foods',
      });
  String get noFoods => _t({'es': 'Ningún alimento', 'en': 'No foods'});
  String get deleteFoodDayQuestion =>
      _t({'es': '¿Eliminar el registro de este día?', 'en': "Delete this day's log?"});
  String get foodDayDeleted => _t({'es': 'Registro del día borrado', 'en': 'Day log deleted'});
  String get seeFoodPain => _t({'es': 'Ver relación con el dolor', 'en': 'See food–pain link'});
  String get foodPainTitle => _t({'es': 'Alimentación y dolor', 'en': 'Food and pain'});
  String dayN(int n) => _t({'es': 'Día $n', 'en': 'Day $n'});
  String get noPainLogged => _t({'es': 'Sin registro de dolor', 'en': 'No pain logged'});
  String get notAvailableYet => _t({'es': 'Aún no disponible', 'en': 'Not available yet'});
  String get painChartTitle =>
      _t({'es': 'Dolor de fondo (0–10)', 'en': 'Background pain (0–10)'});
  String get baselineLabel => _t({
        'es': 'Tu media de los 7 días previos',
        'en': 'Your average over the previous 7 days'
      });
  String baselineValue(String value) => _t({
        'es': 'Tu media de los 7 días previos: $value',
        'en': 'Your average over the previous 7 days: $value'
      });
  String get noBaseline => _t({
        'es': 'Sin registros en los 7 días previos: no hay media para comparar.',
        'en': 'No entries in the previous 7 days: no average to compare with.'
      });
  String painDayStats(String max, String mean, int n) => _t({
        'es': 'Máx. $max · media $mean · ${nRecords(n)}',
        'en': 'Max $max · average $mean · ${nRecords(n)}',
      });
  String vsBaseline(String delta) => _t({
        'es': '$delta frente a tu media previa',
        'en': '$delta vs your previous average'
      });
  String foodsThatDay(int n) => _t({
        'es': 'Comidas de ese día (${foodCount(n)})',
        'en': 'Meals that day (${foodCount(n)})'
      });
  String get foodPainDisclaimer => _t({
        'es': 'Esta vista muestra coincidencias en el tiempo, no causas. Consulta cualquier '
            'cambio en tu alimentación con un profesional sanitario.',
        'en': 'This view shows patterns over time, not causes. Talk to a healthcare '
            'professional before changing your diet.'
      });
  String get previousFoodDay =>
      _t({'es': 'Día anterior con comidas', 'en': 'Previous day with meals'});
  String get nextFoodDay => _t({'es': 'Día siguiente con comidas', 'en': 'Next day with meals'});
  String chartDaySemantics(String day, String value) => _t({
        'es': '$day: $value',
        'en': '$day: $value',
      });
  String chartValueSemantics(String mean, String max, int n) => _t({
        'es': 'media $mean, máximo $max, ${nRecords(n)}',
        'en': 'average $mean, maximum $max, ${nRecords(n)}',
      });
  String get myFoods => _t({'es': 'Mis alimentos', 'en': 'My foods'});
  String get myFoodsHelp => _t({
        'es': 'Añade, cambia el nombre u oculta los alimentos de las listas.',
        'en': 'Add, rename or hide the foods in the lists.'
      });
  String get foodsHelp => _t({
        'es': 'Ocultar un alimento no borra tu historial: solo deja de aparecer en las listas. '
            'Un alimento que ya has usado no se borra, se oculta.',
        'en': 'Hiding a food keeps your history: it just no longer appears in the lists. '
            'A food you have already used is hidden instead of deleted.'
      });
  String get customFoods => _t({'es': 'Añadidos por ti', 'en': 'Added by you'});
  String get basicFoods => _t({'es': 'Alimentos básicos', 'en': 'Basic foods'});
  String get renameFood => _t({'es': 'Cambiar nombre', 'en': 'Rename'});
  String get deleteFoodQuestion => _t({'es': '¿Borrar este alimento?', 'en': 'Delete this food?'});
  String get foodDeleted => _t({'es': 'Alimento borrado', 'en': 'Food deleted'});
  String get foodArchived => _t({
        'es': 'Ya lo has usado algún día: se ha ocultado para conservar tu historial.',
        'en': 'You have already used it: it was hidden to keep your history.'
      });

  // -------------------------------------------------------------- gráficos
  String get dateRange => _t({'es': 'Fechas', 'en': 'Dates'});
  String get range7d => _t({'es': '7 días', 'en': '7 days'});
  String get range30d => _t({'es': '30 días', 'en': '30 days'});
  String get range3m => _t({'es': '3 meses', 'en': '3 months'});
  String get range6m => _t({'es': '6 meses', 'en': '6 months'});
  String get range1y => _t({'es': '1 año', 'en': '1 year'});
  String get rangeAll => _t({'es': 'Todo', 'en': 'All'});
  String get rangeCustom => _t({'es': 'Personalizado…', 'en': 'Custom…'});
  String get groupBy => _t({'es': 'Agrupar', 'en': 'Group by'});
  String get byDay => _t({'es': 'Día', 'en': 'Day'});
  String get byWeek => _t({'es': 'Semana', 'en': 'Week'});
  String get byMonth => _t({'es': 'Mes', 'en': 'Month'});
  String get viewCombined => _t({'es': 'Combinada', 'en': 'Combined'});
  String get viewPerParam => _t({'es': 'Por parámetro', 'en': 'Per parameter'});
  String get viewTable => _t({'es': 'Tabla', 'en': 'Table'});
  String get showTreatments => _t({'es': 'Mostrar tratamientos', 'en': 'Show treatments'});
  String get play => _t({'es': 'Reproducir', 'en': 'Play'});
  String get pause => _t({'es': 'Pausa', 'en': 'Pause'});
  String get export => _t({'es': 'Exportar', 'en': 'Export'});
  String get exportPng => _t({'es': 'Imagen (PNG)', 'en': 'Image (PNG)'});
  String get exportGif => _t({'es': 'GIF animado', 'en': 'Animated GIF'});
  String get exportExcel => _t({'es': 'Excel (.xlsx)', 'en': 'Excel (.xlsx)'});
  String get exportPdf => _t({'es': 'Informe PDF', 'en': 'PDF report'});
  String get noDataInRange => _t({
        'es': 'No hay registros en estas fechas. Cambia el rango o registra tu dolor.',
        'en': 'No entries in this date range. Change the range or log your pain.'
      });
  String get seriesPain => _t({'es': 'Dolor', 'en': 'Pain'});
  String get seriesSurface => _t({'es': 'Superficie', 'en': 'Surface'});
  String get seriesEventIntensity => eventsIntensityTitle;
  String get seriesEventFrequency => eventsFrequencyTitle;
  String get relativeScaleNote => _t({
        'es': 'Escala relativa: 0–100 % de cada parámetro. La frecuencia usa la misma '
            'escala logarítmica que su barra (10–500/min).',
        'en': 'Relative scale: 0–100% of each parameter. Frequency uses the same '
            'logarithmic scale as its slider (10–500/min).'
      });
  String get activeTreatments => _t({'es': 'Tratamientos', 'en': 'Treatments'});
  String get period => _t({'es': 'Periodo', 'en': 'Period'});
  String get records => _t({'es': 'Registros', 'en': 'Entries'});
  String get mean => _t({'es': 'Media', 'en': 'Mean'});
  String get minimum => _t({'es': 'Mínimo', 'en': 'Minimum'});
  String get maximum => _t({'es': 'Máximo', 'en': 'Maximum'});
  String get chartTitle => _t({'es': 'Evolución del dolor', 'en': 'Pain over time'});
  String get reportTitle =>
      _t({'es': 'HOPE · Informe de evolución', 'en': 'HOPE · Progress report'});
  String generatedOn(String date) => _t({'es': 'Generado el $date', 'en': 'Generated on $date'});
  String weekOf(String range) => _t({'es': 'Semana $range', 'en': 'Week $range'});

  // ------------------------------------------------- exportación (Excel/PDF)
  String get sheetSummary => _t({'es': 'Resumen', 'en': 'Summary'});
  String get sheetRecords => _t({'es': 'Registros', 'en': 'Entries'});
  String get sheetTreatments => _t({'es': 'Tratamientos', 'en': 'Treatments'});
  String get sheetInfo => _t({'es': 'Información', 'en': 'Information'});
  String get colPeriodStart => _t({'es': 'Inicio del periodo', 'en': 'Period start'});
  String get colPeriodEnd => _t({'es': 'Fin del periodo', 'en': 'Period end'});
  String get colDateTime => _t({'es': 'Fecha y hora', 'en': 'Date and time'});
  String get colSilhouette => _t({'es': 'Silueta', 'en': 'Silhouette'});
  String get colPain => _t({'es': 'Dolor de fondo (0-10)', 'en': 'Background pain (0-10)'});
  String get colZones => _t({'es': 'Zonas afectadas', 'en': 'Affected areas'});
  String get colZoneCount => _t({'es': 'Nº de zonas', 'en': 'No. of areas'});
  String get colSurface => _t({'es': 'Superficie (%)', 'en': 'Surface (%)'});
  String get colEventIntensity =>
      _t({'es': 'Eventos - intensidad (0-10)', 'en': 'Events - intensity (0-10)'});
  String get colEventFrequency =>
      _t({'es': 'Eventos - frecuencia (/min)', 'en': 'Events - frequency (/min)'});
  String get colEventTypes => _t({'es': 'Tipos de evento', 'en': 'Event types'});
  String get colNote => _t({'es': 'Nota', 'en': 'Note'});
  String get colMedication => _t({'es': 'Medicamento', 'en': 'Medication'});
  String get colRoute => _t({'es': 'Vía', 'en': 'Route'});
  String get colDose => _t({'es': 'Dosis', 'en': 'Dose'});
  String get colUnit => _t({'es': 'Unidad', 'en': 'Unit'});
  String get colStart => _t({'es': 'Inicio', 'en': 'Start'});
  String get colEnd => _t({'es': 'Fin', 'en': 'End'});
  String get colKind => _t({'es': 'Tipo', 'en': 'Type'});
  String get colPeriodKind => _t({'es': 'Periodo', 'en': 'Period'});
  String get colActiveTreatments => _t({'es': 'Tratamientos activos', 'en': 'Active treatments'});
  String colStat(String param, String stat) => '$param - $stat';
  String get infoApp => _t({'es': 'Aplicación', 'en': 'Application'});
  String get infoRange => _t({'es': 'Fechas', 'en': 'Dates'});
  String get infoGrouping => _t({'es': 'Agrupación', 'en': 'Grouping'});
  String get infoExported => _t({'es': 'Exportado el', 'en': 'Exported on'});
  String get infoScale => _t({'es': 'Escala de la gráfica', 'en': 'Chart scale'});
  String get infoColumns => _t({'es': 'Columnas', 'en': 'Columns'});
  String get infoColumnsText => _t({
        'es': 'Resumen: un periodo por fila con el número de registros y la media, el mínimo y '
            'el máximo de cada parámetro (vacío si no hay registros). Registros: un registro por '
            'fila; la frecuencia de eventos queda vacía cuando no hay eventos. Tratamientos: '
            'los tratamientos activos en estas fechas; sin fecha de fin = administración puntual.',
        'en': 'Summary: one period per row with the number of entries and the mean, minimum '
            'and maximum of each parameter (empty when there are no entries). Entries: one '
            'entry per row; event frequency is empty when there are no events. Treatments: '
            'treatments active in these dates; no end date = single administration.'
      });
  String get infoNotice => _t({'es': 'Aviso', 'en': 'Notice'});
  String get summaryByPeriod => _t({'es': 'Resumen por periodo', 'en': 'Summary by period'});
  String get groupedByDay => _t({'es': 'Agrupado por días', 'en': 'Grouped by day'});
  String get groupedByWeek =>
      _t({'es': 'Agrupado por semanas (de lunes a domingo)', 'en': 'Grouped by week (Monday to Sunday)'});
  String get groupedByMonth => _t({'es': 'Agrupado por meses', 'en': 'Grouped by month'});
}
