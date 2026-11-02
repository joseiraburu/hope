// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'pain_record.dart' show isoWithOffset;

/// Momento del día de una comida. Se pueden añadir más en el futuro (por
/// ejemplo, la noche) sin cambiar los datos guardados.
enum MealSlot { morning, afternoon }

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

/// Lo que se comió un día: un registro por día, con los alimentos de la
/// mañana y de la tarde (identificadores de [FoodDef]).
class FoodDay {
  FoodDay({
    required DateTime date,
    this.morning = const [],
    this.afternoon = const [],
    this.updatedAt,
  }) : date = dayOf(date);

  /// Día del registro (medianoche local).
  final DateTime date;
  final List<String> morning;
  final List<String> afternoon;

  /// Última vez que se guardó.
  final DateTime? updatedAt;

  /// Clave del día: «2026-11-02».
  String get key => dayKey(date);

  List<String> slot(MealSlot s) => s == MealSlot.morning ? morning : afternoon;

  /// Alimentos distintos del día (uno que se tomó mañana y tarde cuenta una vez).
  Set<String> get foods => {...morning, ...afternoon};

  bool get isEmpty => morning.isEmpty && afternoon.isEmpty;

  bool contains(String foodId) => morning.contains(foodId) || afternoon.contains(foodId);

  FoodDay copyWith({
    List<String>? morning,
    List<String>? afternoon,
    DateTime? updatedAt,
  }) =>
      FoodDay(
        date: date,
        morning: morning ?? this.morning,
        afternoon: afternoon ?? this.afternoon,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'fecha': key,
        'manana': morning,
        'tarde': afternoon,
        if (updatedAt != null) 'actualizado': isoWithOffset(updatedAt!),
      };

  factory FoodDay.fromJson(Map<String, dynamic> j) {
    final updated = j['actualizado'] as String?;
    return FoodDay(
      date: parseDayKey(j['fecha'] as String),
      morning: [for (final f in (j['manana'] as List<dynamic>? ?? const [])) f as String],
      afternoon: [for (final f in (j['tarde'] as List<dynamic>? ?? const [])) f as String],
      updatedAt: updated == null ? null : DateTime.tryParse(updated)?.toLocal(),
    );
  }
}

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
