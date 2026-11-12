// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'pain_record.dart' show isoWithOffset;

/// Las cinco tomas del día, en orden. [key] es la clave que se guarda en los
/// datos (no cambia con el idioma) y [defaultHour]:[defaultMinute] es la hora
/// habitual, que se usa para los recordatorios y para los días pasados.
enum MealSlot {
  breakfast('desayuno', 8, 0),
  midMorning('almuerzo', 11, 0),
  lunch('comida', 14, 0),
  snack('merienda', 17, 30),
  dinner('cena', 21, 0);

  const MealSlot(this.key, this.defaultHour, this.defaultMinute);

  final String key;
  final int defaultHour;
  final int defaultMinute;

  /// Hora habitual como texto: «08:00».
  String get defaultTime => '${_two(defaultHour)}:${_two(defaultMinute)}';

  static MealSlot? fromKey(String? key) {
    for (final s in values) {
      if (s.key == key) return s;
    }
    return null;
  }
}

/// Un alimento de la lista del usuario.
///
/// Los alimentos básicos vienen de la configuración con una clave estable
/// («bread», «red_meat»...) y su nombre en cada idioma; el usuario puede
/// ocultarlos. Los que añade el usuario solo tienen [customName], que se
/// muestra tal como se escribió en cualquier idioma.
class FoodDef {
  const FoodDef({
    required this.id,
    this.customName,
    this.hidden = false,
    this.builtIn = false,
  });

  final String id;
  final String? customName;

  /// Oculto en las listas, pero se sigue mostrando en el historial.
  final bool hidden;
  final bool builtIn;

  FoodDef copyWith({String? customName, bool? hidden}) => FoodDef(
        id: id,
        customName: customName ?? this.customName,
        hidden: hidden ?? this.hidden,
        builtIn: builtIn,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (customName != null) 'nombre': customName,
        'oculto': hidden,
      };

  factory FoodDef.fromJson(Map<String, dynamic> j) => FoodDef(
        id: j['id'] as String,
        customName: j['nombre'] as String?,
        hidden: (j['oculto'] as bool?) ?? false,
      );
}

/// Lo registrado en una toma: los alimentos, si no se hizo («No realizada»)
/// y a qué hora.
class MealLog {
  const MealLog({this.foods = const [], this.skipped = false, this.time});

  /// Identificadores de [FoodDef].
  final List<String> foods;

  /// La toma no se hizo ese día.
  final bool skipped;

  /// Hora de la toma, «HH:mm» (puede faltar).
  final String? time;

  /// Ni alimentos ni «No realizada»: no hay nada que guardar.
  bool get isEmpty => foods.isEmpty && !skipped;

  MealLog copyWith({List<String>? foods, bool? skipped, String? time, bool clearTime = false}) =>
      MealLog(
        foods: foods ?? this.foods,
        skipped: skipped ?? this.skipped,
        time: clearTime ? null : (time ?? this.time),
      );

  Map<String, dynamic> toJson() => {
        'alimentos': foods,
        if (skipped) 'no_realizada': true,
        if (time != null) 'hora': time,
      };

  factory MealLog.fromJson(Map<String, dynamic> j) {
    final skipped = (j['no_realizada'] as bool?) ?? false;
    return MealLog(
      foods: skipped
          ? const []
          : [for (final f in (j['alimentos'] as List<dynamic>? ?? const [])) f as String],
      skipped: skipped,
      time: normalizeMealTime(j['hora'] as String?),
    );
  }
}

/// Lo que se comió un día: un registro por día con sus cinco tomas.
class FoodDay {
  FoodDay({
    required DateTime date,
    Map<MealSlot, MealLog> meals = const {},
    this.updatedAt,
  })  : date = dayOf(date),
        meals = Map<MealSlot, MealLog>.unmodifiable(<MealSlot, MealLog>{
          for (final e in meals.entries)
            if (!e.value.isEmpty) e.key: e.value,
        });

  /// Atajo: un día con los alimentos de algunas tomas.
  factory FoodDay.withFoods(DateTime date, Map<MealSlot, List<String>> foods) => FoodDay(
        date: date,
        meals: {for (final e in foods.entries) e.key: MealLog(foods: e.value)},
      );

  /// Día del registro (medianoche local).
  final DateTime date;

  /// Tomas con algo registrado (las vacías no se guardan).
  final Map<MealSlot, MealLog> meals;

  /// Última vez que se guardó.
  final DateTime? updatedAt;

  /// Clave del día: «2026-11-02».
  String get key => dayKey(date);

  MealLog meal(MealSlot s) => meals[s] ?? const MealLog();

  /// Alimentos de una toma.
  List<String> slot(MealSlot s) => meal(s).foods;

  bool isSkipped(MealSlot s) => meal(s).skipped;

  /// Alimentos distintos del día (uno que se tomó en dos tomas cuenta una vez).
  Set<String> get foods => {for (final m in meals.values) ...m.foods};

  bool get isEmpty => meals.isEmpty;

  bool contains(String foodId) => meals.values.any((m) => m.foods.contains(foodId));

  /// Tomas con alimentos, en orden.
  List<MealSlot> get eatenSlots =>
      [for (final s in MealSlot.values) if (meal(s).foods.isNotEmpty) s];

  /// Tomas marcadas como «No realizada», en orden.
  List<MealSlot> get skippedSlots => [for (final s in MealSlot.values) if (meal(s).skipped) s];

  FoodDay copyWith({Map<MealSlot, MealLog>? meals, DateTime? updatedAt}) => FoodDay(
        date: date,
        meals: meals ?? this.meals,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'fecha': key,
        'comidas': {
          for (final s in MealSlot.values)
            if (meals[s] != null) s.key: meals[s]!.toJson(),
        },
        if (updatedAt != null) 'actualizado': isoWithOffset(updatedAt!),
      };

  /// Lee un día. Los días de la primera versión de Alimentación (dos
  /// franjas, «manana» y «tarde») pasan al desayuno y a la comida.
  factory FoodDay.fromJson(Map<String, dynamic> j) {
    final updated = j['actualizado'] as String?;
    final meals = <MealSlot, MealLog>{};
    final raw = j['comidas'];
    if (raw is Map<String, dynamic>) {
      for (final e in raw.entries) {
        final slot = MealSlot.fromKey(e.key);
        final value = e.value;
        if (slot != null && value is Map<String, dynamic>) meals[slot] = MealLog.fromJson(value);
      }
    }
    List<String> legacy(String key) =>
        [for (final f in (j[key] as List<dynamic>? ?? const [])) f as String];
    final morning = legacy('manana');
    final afternoon = legacy('tarde');
    if (morning.isNotEmpty && meals[MealSlot.breakfast] == null) {
      meals[MealSlot.breakfast] = MealLog(foods: morning);
    }
    if (afternoon.isNotEmpty && meals[MealSlot.lunch] == null) {
      meals[MealSlot.lunch] = MealLog(foods: afternoon);
    }
    return FoodDay(
      date: parseDayKey(j['fecha'] as String),
      meals: meals,
      updatedAt: updated == null ? null : DateTime.tryParse(updated)?.toLocal(),
    );
  }
}

/// Hora «H:m» normalizada a «HH:mm». Null si no es una hora válida.
String? normalizeMealTime(String? text) {
  if (text == null) return null;
  final m = RegExp(r'^\s*(\d{1,2}):(\d{1,2})\s*$').firstMatch(text);
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return '${_two(h)}:${_two(min)}';
}

/// Hora de un [DateTime] como «HH:mm».
String timeOfDayText(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';

String _two(int n) => n.toString().padLeft(2, '0');

/// Medianoche local del día de [dt].
DateTime dayOf(DateTime dt) {
  final l = dt.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Clave de un día local: «2026-11-02». Es una fecha de calendario, no una
/// hora: no cambia de día con la zona horaria ni con el horario de verano.
String dayKey(DateTime d) {
  final l = d.toLocal();
  return '${l.year.toString().padLeft(4, '0')}-${_two(l.month)}-${_two(l.day)}';
}

/// Día local a partir de su clave «2026-11-02».
DateTime parseDayKey(String key) {
  final p = key.trim().split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

const Map<String, String> _plainLetters = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ñ': 'n', 'ç': 'c',
};

/// Forma de comparar nombres de alimentos: sin mayúsculas, sin tildes y con
/// los espacios simplificados («  Café » y «cafe» son el mismo alimento).
String normalizeFoodName(String name) {
  final out = StringBuffer();
  var pendingSpace = false;
  for (final unit in name.toLowerCase().runes) {
    // Marcas de tilde sueltas (texto descompuesto): se ignoran.
    if (unit >= 0x300 && unit <= 0x36F) continue;
    final ch = String.fromCharCode(unit);
    if (ch.trim().isEmpty) {
      pendingSpace = true;
      continue;
    }
    if (pendingSpace && out.isNotEmpty) out.write(' ');
    pendingSpace = false;
    out.write(_plainLetters[ch] ?? ch);
  }
  return out.toString();
}

/// Longitud máxima del nombre de un alimento.
const int foodNameMaxLength = 40;

/// Nombre tal como se guarda: sin espacios sobrantes y como mucho
/// [foodNameMaxLength] caracteres.
String cleanFoodName(String name) {
  final text = name.trim().split(RegExp(r'\s+')).join(' ');
  return text.length <= foodNameMaxLength ? text : text.substring(0, foodNameMaxLength).trim();
}
