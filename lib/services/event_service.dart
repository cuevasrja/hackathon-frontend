import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackathon_frontend/models/event_response_model.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EventService {
  EventService();

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  Future<EventResponse> fetchEvents({int page = 1, int limit = 10}) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw EventException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw EventException('Token de autenticación no disponible');
    }

    final queryParameters = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/events').replace(
      queryParameters: queryParameters,
    );

    http.Response response;
    try {
      response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw EventException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw EventException('Respuesta inválida del servidor');
      }
      try {
        EventResponse eventRes = EventResponse.fromJson(decoded);
        return eventRes;
      } catch (e) {
        throw EventException('Error al parsear la respuesta');
      }
    }

    if (response.statusCode == 401) {
      throw EventException('Sesión expirada, inicia sesión nuevamente');
    }

    throw EventException('Error inesperado (${response.statusCode})');
  }
}

class EventException implements Exception {
  EventException(this.message);

  final String message;

  @override
  String toString() => message;
}
