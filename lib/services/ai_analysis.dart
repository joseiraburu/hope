// HOPE – registro visual del dolor neuropático crónico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.
//
// Análisis complementario con IA (opcional y desactivado por defecto).
// Envía el resumen agregado del informe a un servicio compatible con la API
// de chat de OpenAI (Groq, OpenRouter, Ollama en local...). Si el servicio
// falla, el informe se queda con el análisis local.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Error al consultar el servicio de IA (el texto se muestra al usuario).
class AiException implements Exception {
  const AiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Configuración del servicio.
class AiConfig {
  const AiConfig({required this.endpoint, required this.model, this.apiKey = ''});

  final String endpoint;
  final String model;
  final String apiKey;

  /// Hay dirección válida (http o https) y modelo.
  bool get isComplete {
    final uri = Uri.tryParse(endpoint.trim());
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty &&
        model.trim().isNotEmpty;
  }
}

/// Cuerpo de la petición (separado para poder probarlo).
Map<String, dynamic> aiRequestBody(AiConfig config, String system, String user) => {
      'model': config.model.trim(),
      'temperature': 0.2,
      'max_tokens': 700,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
    };

/// Saca el texto de la respuesta. Lanza [AiException] si no lo encuentra.
String parseAiResponse(String body) {
  Object? json;
  try {
    json = jsonDecode(body);
  } catch (_) {
    throw const AiException('respuesta no válida');
  }
  if (json is Map<String, dynamic>) {
    final choices = json['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String && content.trim().isNotEmpty) return content.trim();
        }
      }
    }
    final error = json['error'];
    if (error is Map<String, dynamic> && error['message'] is String) {
      throw AiException(error['message'] as String);
    }
  }
  throw const AiException('respuesta sin texto');
}

/// Pide el análisis al servicio. Lanza [AiException] si algo falla.
Future<String> requestAiAnalysis(
  AiConfig config, {
  required String system,
  required String user,
  Duration timeout = const Duration(seconds: 60),
}) async {
  if (!config.isComplete) throw const AiException('configuración incompleta');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.postUrl(Uri.parse(config.endpoint.trim())).timeout(timeout);
    request.headers.contentType = ContentType.json;
    final key = config.apiKey.trim();
    if (key.isNotEmpty) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $key');
    request.add(utf8.encode(jsonEncode(aiRequestBody(config, system, user))));
    final response = await request.close().timeout(timeout);
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        parseAiResponse(body);
      } on AiException catch (e) {
        throw AiException('HTTP ${response.statusCode} · ${e.message}');
      }
      throw AiException('HTTP ${response.statusCode}');
    }
    return parseAiResponse(body);
  } on AiException {
    rethrow;
  } on TimeoutException {
    throw const AiException('tiempo de espera agotado');
  } on SocketException catch (e) {
    throw AiException(e.message.isEmpty ? 'sin conexión' : e.message);
  } on HandshakeException {
    throw const AiException('error de seguridad (TLS)');
  } on HttpException catch (e) {
    throw AiException(e.message);
  } on FormatException catch (e) {
    throw AiException(e.message);
  } finally {
    client.close(force: true);
  }
}
