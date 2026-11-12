// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.
//
// Textos de la app en español (por defecto) e inglés.
// Para añadir un idioma, añade su código a [S.supported] y una entrada con
// ese código en cada texto. Los textos que falten se muestran en español.

import '../models/food.dart' show MealSlot;

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
        'es': 'Guarda en un archivo todos tus registros, tratamientos, alimentación, sueño y ajustes.',
        'en': 'Saves all your entries, treatments, food log, sleep and settings to a file.'
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
        'es': 'Se borrarán todos los registros, tratamientos, la alimentación y el sueño de '
            'este dispositivo. No se puede deshacer.',
        'en': 'All entries, treatments, the food log and sleep on this device will be '
            'deleted. This cannot be undone.'
      });
  String get allDeleted => _t({'es': 'Se han borrado todos los datos', 'en': 'All data deleted'});
  String get dataLocal => _t({
        'es': 'Tus registros se guardan solo en este dispositivo. HOPE no usa '
            'servidores, cuentas, publicidad ni analítica. Solo si activas el análisis '
            'con IA del informe se envía un resumen anónimo al servicio que elijas.',
        'en': 'Your entries are stored only on this device. HOPE uses no '
            'servers, accounts, ads or analytics. Only if you turn on the AI analysis '
            'of the report is an anonymous summary sent to the service you choose.'
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
  /// Nombre de cada toma.
  String meal(MealSlot slot) => switch (slot) {
        MealSlot.breakfast => _t({'es': 'Desayuno', 'en': 'Breakfast'}),
        MealSlot.midMorning => _t({'es': 'Almuerzo', 'en': 'Mid-morning snack'}),
        MealSlot.lunch => _t({'es': 'Comida', 'en': 'Lunch'}),
        MealSlot.snack => _t({'es': 'Merienda', 'en': 'Afternoon snack'}),
        MealSlot.dinner => _t({'es': 'Cena', 'en': 'Dinner'}),
      };
  String get mealSkipped => _t({'es': 'No realizada', 'en': 'Skipped'});
  String get mealTime => _t({'es': 'Hora', 'en': 'Time'});
  String get noMealTime => _t({'es': 'Sin hora', 'en': 'No time'});
  String mealTimeTooltip(String meal) =>
      _t({'es': 'Cambiar la hora · $meal', 'en': 'Change time · $meal'});
  String mealSkippedLine(String meal) =>
      _t({'es': '$meal: no realizada', 'en': '$meal: skipped'});
  String mealLine(String meal, String? time, String foods) => time == null
      ? '$meal: $foods'
      : _t({'es': '$meal ($time): $foods', 'en': '$meal ($time): $foods'});
  String mealsDone(int done, int skipped) => _t({
        'es': '$done de 5 tomas registradas${skipped > 0 ? ' · $skipped no realizadas' : ''}',
        'en': '$done of 5 meals logged${skipped > 0 ? ' · $skipped skipped' : ''}',
      });
  String get completeHope => _t({'es': 'Completa HOPE', 'en': 'Complete HOPE'});
  String get completeHopeHelp => _t({
        'es': 'Lo que llevas registrado hoy:',
        'en': 'What you have logged today:',
      });
  String get checkPain => _t({'es': 'Dolor', 'en': 'Pain'});
  String painLoggedAt(String time) =>
      _t({'es': 'Evaluado hoy a las $time', 'en': 'Rated today at $time'});
  String get painNotLoggedToday =>
      _t({'es': 'Aún no lo has evaluado hoy', 'en': "You haven't rated it today"});
  String get checkSleep => _t({'es': 'Sueño de anoche', 'en': "Last night's sleep"});
  String get notLogged => _t({'es': 'Sin registrar', 'en': 'Not logged'});
  String get checkMeals => _t({'es': 'Comidas', 'en': 'Meals'});
  String get ratePainNow => _t({'es': 'Evaluar el dolor', 'en': 'Rate pain'});
  String get logSleepNow => _t({'es': 'Registrar el sueño', 'en': 'Log sleep'});
  String reminderFor(String meal) =>
      _t({'es': 'Recordatorio: $meal', 'en': 'Reminder: $meal'});
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

  // ------------------------------------------------------------------ sueño
  String get sleep => _t({'es': 'Sueño', 'en': 'Sleep'});
  String get sleepHelp => _t({
        'es': 'Calidad de cada noche (1 a 5) y si dormiste con dolor.',
        'en': 'Quality of each night (1 to 5) and whether you slept with pain.'
      });
  String nightOf(String from, String to) =>
      _t({'es': 'Noche del $from al $to', 'en': 'Night of $from to $to'});
  String get sleepNight => _t({'es': 'Noche', 'en': 'Night'});
  String get sleepQuality => _t({'es': 'Calidad del sueño', 'en': 'Sleep quality'});
  String sleepQualityName(int q) => switch (q) {
        1 => _t({'es': 'Muy malo', 'en': 'Very poor'}),
        2 => _t({'es': 'Malo', 'en': 'Poor'}),
        3 => _t({'es': 'Regular', 'en': 'Fair'}),
        4 => _t({'es': 'Bueno', 'en': 'Good'}),
        _ => _t({'es': 'Muy bueno', 'en': 'Very good'}),
      };
  String sleepQualityValue(int q) => '$q · ${sleepQualityName(q)}';
  String get sleepPainLabel => _t({
        'es': 'Dolor durante la noche (opcional)',
        'en': 'Pain during the night (optional)'
      });
  String get withPain => _t({'es': 'Con dolor', 'en': 'With pain'});
  String get withoutPain => _t({'es': 'Sin dolor', 'en': 'Without pain'});
  String get sleepNoteHint => _t({
        'es': 'Por ejemplo: me desperté varias veces',
        'en': 'For example: woke up several times'
      });
  String get chooseSleepQuality =>
      _t({'es': 'Elige la calidad del sueño (1 a 5)', 'en': 'Choose the sleep quality (1 to 5)'});
  String get sleepSaved => _t({'es': 'Noche guardada', 'en': 'Night saved'});
  String get sleepDeleted => _t({'es': 'Noche borrada', 'en': 'Night deleted'});
  String get deleteSleepQuestion => _t({'es': '¿Borrar esta noche?', 'en': 'Delete this night?'});
  String get sleepExists => _t({
        'es': 'Esta noche ya está registrada: al guardar se actualiza.',
        'en': 'This night is already logged: saving updates it.'
      });
  String get sleepEmpty =>
      _t({'es': 'Aún no has registrado ninguna noche.', 'en': "You haven't logged any nights yet."});
  String get recentNights => _t({'es': 'Noches registradas', 'en': 'Logged nights'});

  // -------------------------------------------------------- recordatorios
  String get reminders => _t({'es': 'Recordatorios', 'en': 'Reminders'});
  String get remindersHelp => _t({
        'es': 'Hasta cinco avisos diarios «Completa HOPE». Ponlos a la hora de tus comidas: '
            'al pulsar el aviso se abre esa toma para evaluar tu dolor y añadir lo que has comido.',
        'en': 'Up to five daily “Complete HOPE” reminders. Set them at your mealtimes: tapping '
            'the reminder opens that meal so you can rate your pain and add what you ate.'
      });
  String remindersActive(int n) => _t({
        'es': n == 0 ? 'Ningún aviso activo' : (n == 1 ? '1 aviso activo' : '$n avisos activos'),
        'en': n == 0 ? 'No reminders on' : (n == 1 ? '1 reminder on' : '$n reminders on'),
      });
  String reminderN(int n) => _t({'es': 'Aviso $n', 'en': 'Reminder $n'});
  String get reminderOpens => _t({'es': 'Abre la toma', 'en': 'Opens meal'});
  String reminderTimeTooltip(int n) =>
      _t({'es': 'Cambiar la hora del aviso $n', 'en': 'Change the time of reminder $n'});
  String get reminderTitle => _t({'es': 'Completa HOPE', 'en': 'Complete HOPE'});
  String reminderBody(String meal) => _t({
        'es': 'Evalúa tu dolor y registra lo que has tomado ($meal).',
        'en': 'Rate your pain and log what you had ($meal).'
      });
  String get remindersChannelName =>
      _t({'es': 'Recordatorios «Completa HOPE»', 'en': '“Complete HOPE” reminders'});
  String get remindersChannelDescription => _t({
        'es': 'Avisos diarios para evaluar el dolor y registrar las comidas.',
        'en': 'Daily reminders to rate pain and log meals.'
      });
  String get notificationsDenied => _t({
        'es': 'HOPE no tiene permiso para mostrar avisos. Puedes darlo en los ajustes del '
            'sistema; mientras tanto, los recordatorios no sonarán.',
        'en': 'HOPE is not allowed to show notifications. You can allow it in the system '
            'settings; until then, reminders will not go off.'
      });
  String get remindersLimitsMobile => _t({
        'es': 'Los avisos se programan para los próximos 12 días y se renuevan cada vez que '
            'abres HOPE. Con el ahorro de batería, algunos móviles los retrasan unos minutos.',
        'en': 'Reminders are scheduled for the next 12 days and renewed every time you open '
            'HOPE. With battery saving, some phones delay them by a few minutes.'
      });
  String get remindersLimitsDesktop => _t({
        'es': 'En el ordenador, HOPE solo puede avisarte mientras está abierta (aunque esté '
            'minimizada). Para recibir los avisos con HOPE cerrada, añádelos a tu calendario.',
        'en': 'On a computer, HOPE can only remind you while it is open (even minimised). To '
            'get reminders with HOPE closed, add them to your calendar.'
      });
  String get exactAlarms => _t({'es': 'Avisos a la hora exacta', 'en': 'Exact-time reminders'});
  String get exactAlarmsHelp => _t({
        'es': 'Android puede retrasar los avisos unos minutos. Permite las alarmas exactas '
            'para que lleguen puntuales.',
        'en': 'Android may delay reminders by a few minutes. Allow exact alarms so they '
            'arrive on time.'
      });
  String get allow => _t({'es': 'Permitir', 'en': 'Allow'});
  String get addToCalendar => _t({'es': 'Añadir al calendario (.ics)', 'en': 'Add to calendar (.ics)'});
  String get addToCalendarHelp => _t({
        'es': 'Crea un archivo con los avisos activos, repetidos cada día, para abrirlo con tu '
            'calendario (Outlook, Google Calendar, Apple…).',
        'en': 'Creates a file with the active reminders, repeating daily, to open with your '
            'calendar (Outlook, Google Calendar, Apple…).'
      });
  String get noRemindersEnabled =>
      _t({'es': 'Activa al menos un aviso.', 'en': 'Turn on at least one reminder.'});
  String get later => _t({'es': 'Más tarde', 'en': 'Later'});
  String get open => _t({'es': 'Abrir', 'en': 'Open'});

  // -------------------------------------------------------- informe completo
  String get fullReport => _t({'es': 'Informe completo', 'en': 'Full report'});
  String get fullReportTitle => _t({'es': 'HOPE · Informe completo', 'en': 'HOPE · Full report'});
  String get fullReportHelp => _t({
        'es': 'Evolución del dolor y su relación con el sueño y la alimentación.',
        'en': 'How your pain has evolved and how it relates to sleep and food.'
      });
  String lastNDays(int n) => _t({'es': 'Últimos $n días', 'en': 'Last $n days'});
  String get insufficientData => _t({'es': 'Datos insuficientes', 'en': 'Insufficient data'});
  String get insufficientDataHelp => _t({
        'es': 'Para sacar conclusiones hacen falta más registros en este periodo. Esto es lo que falta:',
        'en': 'More entries are needed in this period to draw conclusions. This is what is missing:'
      });
  String get reportCoverage => _t({'es': 'Registros del periodo', 'en': 'Entries in this period'});
  String coverageDays(int withAny, int total) => _t({
        'es': 'Días con algún registro: $withAny de $total',
        'en': 'Days with any entry: $withAny of $total'
      });
  String coveragePain(int records, int days) => _t({
        'es': 'Dolor: ${nRecords(records)} en $days ${days == 1 ? 'día' : 'días'}',
        'en': 'Pain: ${nRecords(records)} on $days ${days == 1 ? 'day' : 'days'}'
      });
  String coverageSleep(int nights) => _t({
        'es': 'Sueño: $nights ${nights == 1 ? 'noche' : 'noches'}',
        'en': 'Sleep: $nights ${nights == 1 ? 'night' : 'nights'}'
      });
  String coverageMeals(int eaten, int skipped, int days) => _t({
        'es': 'Comidas: $eaten tomas con alimentos y $skipped no realizadas en $days '
            '${days == 1 ? 'día' : 'días'}',
        'en': 'Meals: $eaten with food and $skipped skipped on $days ${days == 1 ? 'day' : 'days'}'
      });
  String coverageComplete(int days, int total, String pct) => _t({
        'es': 'Días completos (dolor, sueño y comidas): $days de $total ($pct)',
        'en': 'Complete days (pain, sleep and meals): $days of $total ($pct)'
      });
  String get reportPainTitle => _t({'es': 'Evolución del dolor', 'en': 'Pain over time'});
  String reportPainMean(String mean, String min, String max, int days) => _t({
        'es': 'Dolor de fondo: media $mean/10, entre $min y $max ($days días con registros)',
        'en': 'Background pain: average $mean/10, from $min to $max ($days days with entries)'
      });
  String reportEventsMean(String mean) => _t({
        'es': 'Eventos (pinchazos, quemazones…): intensidad media $mean/10',
        'en': 'Events (pricks, burning…): average intensity $mean/10'
      });
  String get trendStable => _t({
        'es': 'Tendencia: estable a lo largo del periodo',
        'en': 'Trend: stable over the period'
      });
  String trendUp(String change) => _t({
        'es': 'Tendencia: en aumento, unos $change puntos a lo largo del periodo',
        'en': 'Trend: rising, about $change points over the period'
      });
  String trendDown(String change) => _t({
        'es': 'Tendencia: en descenso, unos $change puntos a lo largo del periodo',
        'en': 'Trend: falling, about $change points over the period'
      });
  String halves(String first, String second) => _t({
        'es': 'Media de la primera mitad del periodo: $first · de la segunda: $second',
        'en': 'Average in the first half of the period: $first · in the second: $second'
      });
  String frequentZones(String list) =>
      _t({'es': 'Zonas más frecuentes: $list', 'en': 'Most frequent areas: $list'});
  String frequentTypes(String list) =>
      _t({'es': 'Tipos de evento más frecuentes: $list', 'en': 'Most frequent event types: $list'});
  String get reportSleepTitle => _t({'es': 'Sueño', 'en': 'Sleep'});
  String reportSleepMean(String mean, int nights) => _t({
        'es': 'Calidad media: $mean/5 ($nights noches)',
        'en': 'Average quality: $mean/5 ($nights nights)'
      });
  String sleepDistribution(String text) =>
      _t({'es': 'Noches por calidad: $text', 'en': 'Nights by quality: $text'});
  String nightsWithPain(int n, int known) => _t({
        'es': 'Noches con dolor: $n de $known en las que lo indicaste',
        'en': 'Nights with pain: $n of the $known where you said'
      });
  String get sleepTrendStable =>
      _t({'es': 'Tendencia: estable', 'en': 'Trend: stable'});
  String sleepTrendUp(String change) => _t({
        'es': 'Tendencia: mejora, unos $change puntos a lo largo del periodo',
        'en': 'Trend: improving, about $change points over the period'
      });
  String sleepTrendDown(String change) => _t({
        'es': 'Tendencia: empeora, unos $change puntos a lo largo del periodo',
        'en': 'Trend: worsening, about $change points over the period'
      });
  String get reportFoodTitle => _t({'es': 'Alimentación', 'en': 'Food'});
  String foodDaysLine(int days) =>
      _t({'es': 'Días con comidas registradas: $days', 'en': 'Days with meals logged: $days'});
  String mealStats(String meal, int eaten, int skipped) => _t({
        'es': '$meal: $eaten con alimentos · $skipped no realizadas',
        'en': '$meal: $eaten with food · $skipped skipped'
      });
  String frequentFoods(String list) => _t({
        'es': 'Alimentos más frecuentes (días): $list',
        'en': 'Most frequent foods (days): $list'
      });
  String get reportRelationsTitle =>
      _t({'es': 'Relación con el dolor', 'en': 'Links with pain'});
  String get relationsMetric => _t({
        'es': 'Se compara la media del dolor de fondo (0–10) de los días de cada grupo.',
        'en': 'The average background pain (0–10) of the days in each group is compared.'
      });
  String sleepVsPain(String bad, int nBad, String good, int nGood) => _t({
        'es': 'Tras noches malas (1–2): dolor medio $bad ($nBad días). '
            'Tras noches buenas (4–5): $good ($nGood días).',
        'en': 'After poor nights (1–2): average pain $bad ($nBad days). '
            'After good nights (4–5): $good ($nGood days).'
      });
  String sleepCorrelation(String r, String meaning) => _t({
        'es': 'Calidad del sueño y dolor del día siguiente: r = $r ($meaning).',
        'en': 'Sleep quality and next-day pain: r = $r ($meaning).'
      });
  String get correlationNegative =>
      _t({'es': 'a peor sueño, más dolor', 'en': 'worse sleep, more pain'});
  String get correlationPositive =>
      _t({'es': 'a mejor sueño, más dolor', 'en': 'better sleep, more pain'});
  String get correlationNone => _t({'es': 'sin relación clara', 'en': 'no clear link'});
  String nightPainVsPain(String withP, int nWith, String without, int nWithout) => _t({
        'es': 'Tras noches con dolor: $withP ($nWith días). Tras noches sin dolor: $without '
            '($nWithout días).',
        'en': 'After nights with pain: $withP ($nWith days). After nights without pain: '
            '$without ($nWithout days).'
      });
  String foodsCompared(int n, int min) => _t({
        'es': 'Alimentos comparados: $n (los que tomaste al menos $min días y no tomaste '
            'otros $min).',
        'en': 'Foods compared: $n (those you had on at least $min days and not on another $min).'
      });
  String get foodMorePain => _t({'es': 'Coincide con más dolor', 'en': 'Coincides with more pain'});
  String get foodLessPain => _t({'es': 'Coincide con menos dolor', 'en': 'Coincides with less pain'});
  String get foodSameDay => _t({'es': 'mismo día', 'en': 'same day'});
  String get foodNextDay => _t({'es': 'día siguiente', 'en': 'next day'});
  String comparisonText(String withM, String withoutM, String diff, int nWith, int nWithout) => _t({
        'es': '$withM frente a $withoutM ($diff; $nWith y $nWithout días)',
        'en': '$withM vs $withoutM ($diff; $nWith and $nWithout days)'
      });
  String get noFoodPattern => _t({
        'es': 'Ningún alimento coincide con una diferencia de dolor de 1 punto o más.',
        'en': 'No food coincides with a pain difference of 1 point or more.'
      });
  String skippedVsPain(String withM, int nWith, String withoutM, int nWithout) => _t({
        'es': 'Días con alguna toma no realizada: dolor medio $withM ($nWith días). '
            'Días sin tomas saltadas: $withoutM ($nWithout días).',
        'en': 'Days with a skipped meal: average pain $withM ($nWith days). '
            'Days with no skipped meals: $withoutM ($nWithout days).'
      });
  String missingPainDays(int have, int need) => _t({
        'es': 'Hacen falta al menos $need días con registro de dolor en el periodo (hay $have).',
        'en': 'At least $need days with a pain entry are needed in the period (there are $have).'
      });
  String missingSleep(int have, int need) => _t({
        'es': 'Hacen falta al menos $need noches registradas (hay $have).',
        'en': 'At least $need logged nights are needed (there are $have).'
      });
  String missingFood(int have, int need) => _t({
        'es': 'Hacen falta al menos $need días con comidas registradas (hay $have).',
        'en': 'At least $need days with meals logged are needed (there are $have).'
      });
  String missingSleepPain(int have, int need) => _t({
        'es': 'Para relacionar sueño y dolor hacen falta al menos $need días con los dos '
            'registrados (hay $have).',
        'en': 'To link sleep and pain, at least $need days with both logged are needed '
            '(there are $have).'
      });
  String missingFoodPain(int have, int need) => _t({
        'es': 'Para relacionar alimentación y dolor hacen falta al menos $need días con comidas '
            'y dolor registrados (hay $have).',
        'en': 'To link food and pain, at least $need days with meals and pain logged are '
            'needed (there are $have).'
      });
  String get missingSleepGroups => _t({
        'es': 'Para comparar hacen falta al menos 2 noches malas (1–2) y 2 buenas (4–5).',
        'en': 'At least 2 poor nights (1–2) and 2 good nights (4–5) are needed to compare.'
      });
  String get reportConclusions => _t({'es': 'Conclusiones', 'en': 'Conclusions'});
  String cPainStable(String mean) => _t({
        'es': 'El dolor de fondo se ha mantenido estable, con una media de $mean/10.',
        'en': 'Background pain has stayed stable, averaging $mean/10.'
      });
  String cPainUp(String change, String mean) => _t({
        'es': 'El dolor de fondo ha aumentado unos $change puntos a lo largo del periodo '
            '(media $mean/10).',
        'en': 'Background pain has risen by about $change points over the period '
            '(average $mean/10).'
      });
  String cPainDown(String change, String mean) => _t({
        'es': 'El dolor de fondo ha bajado unos $change puntos a lo largo del periodo '
            '(media $mean/10).',
        'en': 'Background pain has fallen by about $change points over the period '
            '(average $mean/10).'
      });
  String cSleepMean(String mean) => _t({
        'es': 'La calidad media del sueño ha sido $mean sobre 5.',
        'en': 'Average sleep quality has been $mean out of 5.'
      });
  String cSleepWorse(String bad, String good) => _t({
        'es': 'Los días después de dormir mal, el dolor fue mayor ($bad frente a $good tras '
            'dormir bien).',
        'en': 'On days after sleeping poorly, pain was higher ($bad vs $good after sleeping well).'
      });
  String cSleepBetter(String bad, String good) => _t({
        'es': 'Los días después de dormir mal, el dolor fue menor ($bad frente a $good tras '
            'dormir bien).',
        'en': 'On days after sleeping poorly, pain was lower ($bad vs $good after sleeping well).'
      });
  String get cSleepNoDiff => _t({
        'es': 'No se ve una diferencia clara de dolor entre los días después de dormir bien y '
            'después de dormir mal.',
        'en': 'There is no clear difference in pain between days after good and poor nights.'
      });
  String cNightPain(String withP, String without) => _t({
        'es': 'Tras las noches con dolor, el dolor del día fue mayor ($withP frente a $without).',
        'en': 'After nights with pain, daytime pain was higher ($withP vs $without).'
      });
  String cFoodMore(String names) => _t({
        'es': 'Los días con $names coincidieron con más dolor (el mismo día o el siguiente).',
        'en': 'Days with $names coincided with more pain (the same or the next day).'
      });
  String cFoodLess(String names) => _t({
        'es': 'Los días con $names coincidieron con menos dolor (el mismo día o el siguiente).',
        'en': 'Days with $names coincided with less pain (the same or the next day).'
      });
  String get cFoodNone => _t({
        'es': 'No se observa ningún alimento que coincida con cambios claros del dolor.',
        'en': 'No food coincides with clear changes in pain.'
      });
  String cSkippedMore(String diff) => _t({
        'es': 'Los días con alguna toma no realizada, el dolor fue unos $diff puntos mayor.',
        'en': 'On days with a skipped meal, pain was about $diff points higher.'
      });
  String cSkippedLess(String diff) => _t({
        'es': 'Los días con alguna toma no realizada, el dolor fue unos $diff puntos menor.',
        'en': 'On days with a skipped meal, pain was about $diff points lower.'
      });
  String get cInsufficient => _t({
        'es': 'Todavía no hay datos suficientes para sacar conclusiones. Registra el dolor, el '
            'sueño y las comidas cada día.',
        'en': 'There is not enough data yet to draw conclusions. Log your pain, sleep and '
            'meals every day.'
      });
  String get cAssociationNote => _t({
        'es': 'Son coincidencias en tus registros, no pruebas de causa: con pocos días pueden '
            'deberse al azar.',
        'en': 'These are coincidences in your entries, not proof of cause: with few days they '
            'may be due to chance.'
      });
  String get reportNotice => _t({
        'es': 'Este informe no sustituye la valoración de un profesional sanitario.',
        'en': 'This report does not replace an assessment by a healthcare professional.'
      });
  String get reportExportPdf => _t({'es': 'Guardar o compartir en PDF', 'en': 'Save or share as PDF'});

  // ------------------------------------------------------- análisis con IA
  String get aiTitle => _t({'es': 'Análisis con IA', 'en': 'AI analysis'});
  String get aiOptional =>
      _t({'es': 'Análisis con IA (opcional)', 'en': 'AI analysis (optional)'});
  String get aiOn => _t({'es': 'Activado', 'en': 'On'});
  String get aiOff => _t({'es': 'Desactivado', 'en': 'Off'});
  String get aiHelp => _t({
        'es': 'Desactivado por defecto. Si lo activas, el informe completo puede pedir a un '
            'servicio de IA que redacte un análisis complementario. El informe funciona igual '
            'sin IA.',
        'en': 'Off by default. If you turn it on, the full report can ask an AI service to '
            'write a complementary analysis. The report works the same without AI.'
      });
  String get aiWhatIsSent => _t({'es': 'Qué se envía', 'en': 'What is sent'});
  String get aiWhatIsSentBody => _t({
        'es': 'Solo el resumen del informe con cifras agregadas del periodo: medias de dolor y '
            'sueño, tendencias, número de días, tomas registradas y no realizadas, y los '
            'alimentos con sus comparaciones. No se envían tu nombre, fechas, notas, zonas '
            'del cuerpo ni tratamientos.',
        'en': 'Only the report summary with aggregated figures for the period: pain and sleep '
            'averages, trends, number of days, logged and skipped meals, and the foods with '
            'their comparisons. Your name, dates, notes, body areas and treatments are not sent.'
      });
  String get aiPrivacyNotice => _t({
        'es': 'El servicio de IA es de terceros y tiene su propia política de privacidad. Son '
            'datos de salud: actívalo solo si estás de acuerdo. Puedes desactivarlo cuando '
            'quieras.',
        'en': 'The AI service is a third party with its own privacy policy. This is health '
            'data: only turn it on if you agree. You can turn it off at any time.'
      });
  String get aiConsentTitle => _t({'es': '¿Activar el análisis con IA?', 'en': 'Turn on AI analysis?'});
  String get aiConsentAccept => _t({'es': 'Acepto y lo activo', 'en': 'I agree, turn it on'});
  String get aiEndpoint =>
      _t({'es': 'Dirección del servicio (API compatible con OpenAI)', 'en': 'Service URL (OpenAI-compatible API)'});
  String get aiEndpointHint => 'https://api.groq.com/openai/v1/chat/completions';
  String get aiModel => _t({'es': 'Modelo', 'en': 'Model'});
  String get aiModelHint => _t({'es': 'p. ej. llama-3.3-70b-versatile', 'en': 'e.g. llama-3.3-70b-versatile'});
  String get aiKey => _t({'es': 'Clave de acceso (si el servicio la pide)', 'en': 'Access key (if the service needs one)'});
  String get aiKeyHelp => _t({
        'es': 'Se guarda solo en este dispositivo y no se incluye en la copia de seguridad.',
        'en': 'Stored only on this device and not included in the backup.'
      });
  String get aiExamples => _t({
        'es': 'Servicios de libre acceso compatibles: Groq u OpenRouter (con una cuenta gratuita '
            'y su clave), o Ollama en tu propio ordenador '
            '(http://localhost:11434/v1/chat/completions, sin clave y sin enviar nada fuera de él).',
        'en': 'Compatible free-access services: Groq or OpenRouter (with a free account and its '
            'key), or Ollama on your own computer (http://localhost:11434/v1/chat/completions, '
            'no key and nothing leaves the computer).'
      });
  String get aiTest => _t({'es': 'Probar conexión', 'en': 'Test connection'});
  String get aiTestOk => _t({'es': 'Conexión correcta', 'en': 'Connection works'});
  String aiError(String detail) =>
      _t({'es': 'No se ha podido conectar: $detail', 'en': 'Could not connect: $detail'});
  String get aiAsk => _t({'es': 'Pedir el análisis a la IA', 'en': 'Ask the AI for an analysis'});
  String get aiWorking => _t({'es': 'Consultando a la IA…', 'en': 'Asking the AI…'});
  String get aiFailed => _t({
        'es': 'La IA no ha respondido. Se muestra solo el análisis local.',
        'en': 'The AI did not respond. Only the local analysis is shown.'
      });
  String get aiResultTitle =>
      _t({'es': 'Análisis complementario con IA', 'en': 'Complementary AI analysis'});
  String get aiResultNotice => _t({
        'es': 'Texto generado por IA a partir del resumen anterior. Puede contener errores y no '
            'es una valoración médica.',
        'en': 'AI-generated text based on the summary above. It may contain errors and is not '
            'a medical assessment.'
      });
  String get aiNotConfigured => _t({
        'es': 'Falta la dirección del servicio o el modelo (Ajustes → Análisis con IA).',
        'en': 'The service URL or the model is missing (Settings → AI analysis).'
      });
  String get aiOffInReport => _t({
        'es': 'Puedes activar un análisis complementario con IA en Ajustes. Es opcional.',
        'en': 'You can turn on a complementary AI analysis in Settings. It is optional.'
      });
  String get aiSystemPrompt => _t({
        'es': 'Eres un asistente que redacta un resumen de los registros personales de una '
            'persona con dolor neuropático crónico. Describe solo patrones y coincidencias que '
            'aparezcan en los datos que se te dan, en especial entre el dolor, el sueño y la '
            'alimentación. No diagnostiques, no atribuyas causas médicas, no recomiendes '
            'tratamientos, dietas, alimentos ni cambios de hábitos. Si hay pocos datos, dilo. '
            'Recuerda que una coincidencia no demuestra una causa. Responde en español, en '
            'frases claras y sencillas, con un máximo de 200 palabras.',
        'en': 'You are an assistant writing a summary of the personal entries of someone with '
            'chronic neuropathic pain. Only describe patterns and coincidences that appear in '
            'the data given, especially between pain, sleep and food. Do not diagnose, do not '
            'attribute medical causes, and do not recommend treatments, diets, foods or habit '
            'changes. If there is little data, say so. Remember that a coincidence does not '
            'prove a cause. Answer in English, in clear and simple sentences, in at most 200 words.'
      });
  String aiUserIntro(int days) => _t({
        'es': 'Resumen de los registros de los últimos $days días (cifras agregadas, sin fechas):',
        'en': 'Summary of the entries for the last $days days (aggregated figures, no dates):'
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
