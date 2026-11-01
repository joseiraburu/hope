// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Un archivo dentro de un ZIP.
class ZipEntry {
  ZipEntry(this.name, this.data);

  ZipEntry.text(this.name, String text) : data = Uint8List.fromList(utf8.encode(text));

  final String name;
  final Uint8List data;
}

final Uint32List _crcTable = () {
  final t = Uint32List(256);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    t[n] = c;
  }
  return t;
}();

/// CRC-32 (el de ZIP y PNG).
int crc32(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

/// Crea un archivo ZIP (comprimido con deflate cuando reduce el tamaño).
Uint8List buildZip(List<ZipEntry> entries, {DateTime? time}) {
  final t = time ?? DateTime.now();
  final dosTime = (t.hour << 11) | (t.minute << 5) | (t.second ~/ 2);
  final dosDate = ((t.year - 1980).clamp(0, 127).toInt() << 9) | (t.month << 5) | t.day;
  final out = BytesBuilder(copy: false);
  final central = BytesBuilder(copy: false);
  var offset = 0;

  void u16(BytesBuilder b, int v) => b.add([v & 0xff, (v >> 8) & 0xff]);
  void u32(BytesBuilder b, int v) =>
      b.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);

  for (final e in entries) {
    final name = utf8.encode(e.name);
    final crc = crc32(e.data);
    final deflated = ZLibEncoder(raw: true, level: 6).convert(e.data);
    final useDeflate = deflated.length < e.data.length;
    final payload = useDeflate ? deflated : e.data;
    final method = useDeflate ? 8 : 0;

    final local = BytesBuilder(copy: false);
    u32(local, 0x04034b50);
    u16(local, 20);
    u16(local, 0x0800); // nombres en UTF-8
    u16(local, method);
    u16(local, dosTime);
    u16(local, dosDate);
    u32(local, crc);
    u32(local, payload.length);
    u32(local, e.data.length);
    u16(local, name.length);
    u16(local, 0);
    local.add(name);
    final header = local.takeBytes();
    out.add(header);
    out.add(payload);

    u32(central, 0x02014b50);
    u16(central, 20);
    u16(central, 20);
    u16(central, 0x0800);
    u16(central, method);
    u16(central, dosTime);
    u16(central, dosDate);
    u32(central, crc);
    u32(central, payload.length);
    u32(central, e.data.length);
    u16(central, name.length);
    u16(central, 0);
    u16(central, 0);
    u16(central, 0);
    u16(central, 0);
    u32(central, 0);
    u32(central, offset);
    central.add(name);

    offset += header.length + payload.length;
  }
  final cd = central.takeBytes();
  out.add(cd);
  final end = BytesBuilder(copy: false);
  u32(end, 0x06054b50);
  u16(end, 0);
  u16(end, 0);
  u16(end, entries.length);
  u16(end, entries.length);
  u32(end, cd.length);
  u32(end, offset);
  u16(end, 0);
  out.add(end.takeBytes());
  return out.takeBytes();
}
