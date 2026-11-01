// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.
//
// Escritor mínimo de hojas de cálculo Excel (.xlsx, Office Open XML).
// Las fechas se guardan como fechas reales y los números como números, para
// que se puedan filtrar, ordenar y calcular en Excel, LibreOffice o Google
// Sheets.

import 'dart:typed_data';

import 'zip_writer.dart';

/// Fecha y hora (se muestra como «dd/mm/aaaa hh:mm»).
class XlsxDateTime {
  const XlsxDateTime(this.value, {this.withTime = true});

  final DateTime value;
  final bool withTime;
}

/// Número con un formato de decimales fijo («0,0»).
class XlsxDecimal {
  const XlsxDecimal(this.value);

  final double value;
}

/// Una hoja: la primera fila es la cabecera.
class XlsxSheet {
  XlsxSheet({
    required this.name,
    required this.header,
    required this.rows,
    this.columnWidths = const [],
    this.wrapColumns = const {},
  });

  final String name;
  final List<String> header;

  /// Celdas: String, int, double, [XlsxDecimal], [XlsxDateTime] o null.
  final List<List<Object?>> rows;
  final List<double> columnWidths;

  /// Columnas (desde 0) con texto ajustado en varias líneas.
  final Set<int> wrapColumns;
}

// Estilos (índices de cellXfs en styles.xml).
const _styleDefault = 0;
const _styleHeader = 1;
const _styleDateTime = 2;
const _styleDate = 3;
const _styleDecimal = 4;
const _styleWrap = 5;

/// Fecha en el sistema de Excel (días desde el 30/12/1899).
double excelSerial(DateTime d) {
  final naive = DateTime.utc(d.year, d.month, d.day, d.hour, d.minute, d.second);
  return naive.difference(DateTime.utc(1899, 12, 30)).inSeconds / 86400.0;
}

/// Letras de una columna: 0 → A, 25 → Z, 26 → AA.
String columnName(int index) {
  var n = index + 1;
  var s = '';
  while (n > 0) {
    final r = (n - 1) % 26;
    s = String.fromCharCode(65 + r) + s;
    n = (n - 1) ~/ 26;
  }
  return s;
}

String _xml(String text) {
  final b = StringBuffer();
  for (final rune in text.runes) {
    if (rune == 0x26) {
      b.write('&amp;');
    } else if (rune == 0x3C) {
      b.write('&lt;');
    } else if (rune == 0x3E) {
      b.write('&gt;');
    } else if (rune == 0x22) {
      b.write('&quot;');
    } else if (rune < 0x20 && rune != 0x09 && rune != 0x0A && rune != 0x0D) {
      // Caracteres de control no válidos en XML.
    } else {
      b.writeCharCode(rune);
    }
  }
  return b.toString();
}

String _num(num v) {
  if (v is int) return '$v';
  final d = v.toDouble();
  if (d.isNaN || d.isInfinite) return '0';
  return d == d.roundToDouble() && d.abs() < 1e15 ? d.toInt().toString() : d.toString();
}

String _cell(String ref, Object? value, {bool header = false, bool wrap = false}) {
  if (value == null) return '';
  if (value is String) {
    final style = header ? _styleHeader : (wrap ? _styleWrap : _styleDefault);
    final space = value != value.trim() ? ' xml:space="preserve"' : '';
    return '<c r="$ref" t="inlineStr" s="$style"><is><t$space>${_xml(value)}</t></is></c>';
  }
  if (value is XlsxDateTime) {
    final style = value.withTime ? _styleDateTime : _styleDate;
    return '<c r="$ref" s="$style"><v>${_num(excelSerial(value.value))}</v></c>';
  }
  if (value is XlsxDecimal) {
    return '<c r="$ref" s="$_styleDecimal"><v>${_num(value.value)}</v></c>';
  }
  if (value is num) {
    return '<c r="$ref"><v>${_num(value)}</v></c>';
  }
  return _cell(ref, value.toString(), wrap: wrap);
}

String _sheetXml(XlsxSheet sheet) {
  final b = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n')
    ..write('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">')
    ..write('<sheetViews><sheetView workbookViewId="0">'
        '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
        '<selection pane="bottomLeft" activeCell="A2" sqref="A2"/>'
        '</sheetView></sheetViews>')
    ..write('<sheetFormatPr defaultRowHeight="15"/>');
  if (sheet.columnWidths.isNotEmpty) {
    b.write('<cols>');
    for (var i = 0; i < sheet.columnWidths.length; i++) {
      b.write('<col min="${i + 1}" max="${i + 1}" width="${sheet.columnWidths[i]}" customWidth="1"/>');
    }
    b.write('</cols>');
  }
  b.write('<sheetData>');
  b.write('<row r="1">');
  for (var c = 0; c < sheet.header.length; c++) {
    b.write(_cell('${columnName(c)}1', sheet.header[c], header: true));
  }
  b.write('</row>');
  for (var r = 0; r < sheet.rows.length; r++) {
    final row = sheet.rows[r];
    b.write('<row r="${r + 2}">');
    for (var c = 0; c < row.length; c++) {
      b.write(_cell('${columnName(c)}${r + 2}', row[c], wrap: sheet.wrapColumns.contains(c)));
    }
    b.write('</row>');
  }
  b.write('</sheetData>');
  if (sheet.header.isNotEmpty) {
    final last = '${columnName(sheet.header.length - 1)}${sheet.rows.length + 1}';
    b.write('<autoFilter ref="A1:$last"/>');
  }
  b.write('</worksheet>');
  return b.toString();
}

const _stylesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<numFmts count="3">'
    '<numFmt numFmtId="164" formatCode="dd/mm/yyyy hh:mm"/>'
    '<numFmt numFmtId="165" formatCode="dd/mm/yyyy"/>'
    '<numFmt numFmtId="166" formatCode="0.0"/>'
    '</numFmts>'
    '<fonts count="2">'
    '<font><sz val="11"/><name val="Calibri"/><family val="2"/></font>'
    '<font><b/><sz val="11"/><name val="Calibri"/><family val="2"/></font>'
    '</fonts>'
    '<fills count="3">'
    '<fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill>'
    '<fill><patternFill patternType="solid"><fgColor rgb="FFF1EDE8"/><bgColor indexed="64"/></patternFill></fill>'
    '</fills>'
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
    '<cellXfs count="6">'
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
    '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>'
    '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
    '<xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
    '<xf numFmtId="166" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1">'
    '<alignment wrapText="1" vertical="top"/></xf>'
    '</cellXfs>'
    '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
    '</styleSheet>';

/// Crea el archivo .xlsx con las hojas indicadas.
Uint8List buildXlsx(List<XlsxSheet> sheets, {DateTime? time}) {
  final ct = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n')
    ..write('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">')
    ..write('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>')
    ..write('<Default Extension="xml" ContentType="application/xml"/>')
    ..write('<Override PartName="/xl/workbook.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>')
    ..write('<Override PartName="/xl/styles.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>');
  for (var i = 0; i < sheets.length; i++) {
    ct.write('<Override PartName="/xl/worksheets/sheet${i + 1}.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>');
  }
  ct.write('</Types>');

  const rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" '
      'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
      'Target="xl/workbook.xml"/>'
      '</Relationships>';

  final wb = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n')
    ..write('<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">')
    ..write('<bookViews><workbookView/></bookViews><sheets>');
  final wbRels = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n')
    ..write('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
  for (var i = 0; i < sheets.length; i++) {
    final name = _xml(sheets[i].name.replaceAll(RegExp(r'[\[\]\*\?/\\:]'), ' '));
    final safe = name.length > 31 ? name.substring(0, 31) : name;
    wb.write('<sheet name="$safe" sheetId="${i + 1}" r:id="rId${i + 1}"/>');
    wbRels.write('<Relationship Id="rId${i + 1}" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
        'Target="worksheets/sheet${i + 1}.xml"/>');
  }
  wb.write('</sheets></workbook>');
  wbRels.write('<Relationship Id="rId${sheets.length + 1}" '
      'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
      'Target="styles.xml"/></Relationships>');

  return buildZip([
    ZipEntry.text('[Content_Types].xml', ct.toString()),
    ZipEntry.text('_rels/.rels', rels),
    ZipEntry.text('xl/workbook.xml', wb.toString()),
    ZipEntry.text('xl/_rels/workbook.xml.rels', wbRels.toString()),
    ZipEntry.text('xl/styles.xml', _stylesXml),
    for (var i = 0; i < sheets.length; i++)
      ZipEntry.text('xl/worksheets/sheet${i + 1}.xml', _sheetXml(sheets[i])),
  ], time: time);
}
