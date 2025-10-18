import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIChatService {
  const AIChatService();

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  Future<AIChatReply> sendMessage({
    required String prompt,
    String? conversationId,
  }) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw AIChatException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw AIChatException('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$baseUrl/api/ai/chat');

    final payload = <String, dynamic>{'message': prompt.trim()};

    if (conversationId != null && conversationId.isNotEmpty) {
      payload['conversationId'] = conversationId;
    }

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));
    } on Exception {
      throw AIChatException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      return _parseResponse(decoded);
    }

    if (response.statusCode == 401) {
      throw AIChatException('Sesión expirada, inicia sesión nuevamente');
    }

    if (response.statusCode == 400 || response.statusCode == 422) {
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      final message = decoded is Map<String, dynamic>
          ? decoded['message'] as String? ?? 'Solicitud inválida'
          : 'Solicitud inválida';
      throw AIChatException(message);
    }

    throw AIChatException('Error inesperado (${response.statusCode})');
  }

  AIChatReply _parseResponse(dynamic decoded) {
    if (decoded is String) {
      return AIChatReply(message: decoded);
    }

    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return AIChatReply(message: message);
      }

      final success = decoded['success'];
      if (success is bool && success) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          final response = data['response'];
          final conversationId = data['conversationId'];
          if (response is String && response.trim().isNotEmpty) {
            return AIChatReply(
              message: response,
              conversationId: conversationId is String ? conversationId : null,
            );
          }
        }
      }
    }

    throw AIChatException('Respuesta inválida del servidor');
  }
}

class AIChatException implements Exception {
  AIChatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AIChatReply {
  const AIChatReply({required this.message, this.conversationId});

  final String message;
  final String? conversationId;
}
