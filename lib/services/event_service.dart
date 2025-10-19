import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackathon_frontend/models/event_model.dart';
import 'package:hackathon_frontend/models/event_response_model.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EventService {
  EventService();

  String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://hackathon-back-theta.vercel.app';

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

    final uri = Uri.parse(
      '$baseUrl/api/events',
    ).replace(queryParameters: queryParameters);

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

  Future<Event> createEvent({
    required String name,
    required String description,
    required DateTime timeBegin,
    DateTime? timeEnd,
    required int placeId,
    int? categoryId, // Add this
    int? minAge,
    String? status,
    required String visibility,
    int? communityId,
    String? externalUrl,
  }) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw EventException('API_BASE_URL no está configurado');
    }

    if (visibility.toUpperCase() == 'PUBLIC' && communityId == null) {
      throw EventException('Debes indicar la comunidad para eventos públicos');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw EventException('Token de autenticación no disponible');
    }

    final organizerId = prefs.getInt(LoginStorageKeys.userId);
    if (organizerId == null) {
      throw EventException('Información del usuario no disponible');
    }

    final uri = Uri.parse('$baseUrl/api/events');

    final payload = <String, dynamic>{
      'name': name.trim(),
      'description': description.trim(),
      'timeBegin': timeBegin.toUtc().toIso8601String(),
      'timeEnd': (timeEnd ?? timeBegin).toUtc().toIso8601String(),
      'visibility': visibility,
      'placeId': placeId,
      'organizerId': organizerId,
    };

    if (minAge != null) {
      payload['minAge'] = minAge;
    }

    if (status != null && status.isNotEmpty) {
      payload['status'] = status;
    }

    if (communityId != null) {
      payload['communityId'] = communityId;
    }

    if (externalUrl != null && externalUrl.trim().isNotEmpty) {
      payload['externalUrl'] = externalUrl.trim();
    }

    if (categoryId != null) {
      payload['categoryId'] = categoryId;
    }

    http.Response response;
    response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    final decodedBody = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : null;

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (decodedBody is Map<String, dynamic>) {
        final eventData = decodedBody['event'] ?? decodedBody;
        if (eventData is Map<String, dynamic>) {
          return Event.fromJson(eventData);
        }
      }
      throw EventException('Respuesta inválida al crear el evento');
    }

    if (response.statusCode == 400 || response.statusCode == 422) {
      print(decodedBody);
      print("Response Body: ${response.body}");
      print("Response Status: ${response.statusCode}");
      final message = decodedBody is Map<String, dynamic>
          ? decodedBody['message'] as String? ?? 'Datos inválidos'
          : 'Datos inválidos';
      throw EventException(message);
    }

    if (response.statusCode == 401) {
      throw EventException('Sesión expirada, inicia sesión nuevamente');
    }

    final message = decodedBody is Map<String, dynamic>
        ? decodedBody['message'] as String? ?? 'No fue posible crear el evento'
        : 'No fue posible crear el evento';
    throw EventException(message);
  }

  Future<List<Event>> fetchOrganizedEvents() async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw EventException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw EventException('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$baseUrl/api/users/me/events');

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
      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : [];

      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Event.fromJson)
            .toList();
      }

      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(Event.fromJson)
              .toList();
        }
      }

      throw EventException('Respuesta inválida del servidor');
    }

    if (response.statusCode == 401) {
      throw EventException('Sesión expirada, inicia sesión nuevamente');
    }

    throw EventException('Error inesperado (${response.statusCode})');
  }

  Future<List<MyEvent>> fetchJoinedEvents() async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw EventException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw EventException('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$baseUrl/api/users/me/events/joined');

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
      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : [];

      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(MyEvent.fromJson)
            .toList();
      }

      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(MyEvent.fromJson)
              .toList();
        }
      }

      throw EventException('Respuesta inválida del servidor');
    }

    if (response.statusCode == 401) {
      throw EventException('Sesión expirada, inicia sesión nuevamente');
    }

    throw EventException('Error inesperado (${response.statusCode})');
  }

  Future<Event> updateEventVisibility({
    required int eventId,
    required String visibility,
  }) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw EventException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw EventException('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$baseUrl/api/events/$eventId');

    http.Response response;
    try {
      response = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'visibility': visibility}),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw EventException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return Event.fromJson(decoded);
      }
      throw EventException('Respuesta inválida del servidor');
    }

    if (response.statusCode == 401) {
      throw EventException('Sesión expirada, inicia sesión nuevamente');
    }

    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    final message = decoded is Map<String, dynamic>
        ? decoded['message'] as String? ??
              'No fue posible actualizar la visibilidad del evento'
        : 'No fue posible actualizar la visibilidad del evento';
    throw EventException(message);
  }

  Future<EventResponse> fetchCommunityEvents(
    int communityId, {
    String? status,
    String? visibility,
    bool? upcomingOnly,
    int page = 1,
    int limit = 10,
  }) async {
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

    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    if (visibility != null && visibility.isNotEmpty) {
      queryParameters['visibility'] = visibility;
    }

    if (upcomingOnly != null) {
      queryParameters['upcomingOnly'] = upcomingOnly.toString();
    }

    final uri = Uri.parse(
      '$baseUrl/api/communities/$communityId/events',
    ).replace(queryParameters: queryParameters);

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
      if (decoded is Map<String, dynamic>) {
        return EventResponse.fromJson(decoded);
      }
      if (decoded is List) {
        final events = decoded
            .whereType<Map<String, dynamic>>()
            .map(Event.fromJson)
            .toList();
        return EventResponse(
          events: events,
          total: events.length,
          page: 1,
          limit: limit,
        );
      }
      throw EventException('Respuesta inválida del servidor');
    }

    if (response.statusCode == 401) {
      throw EventException('Sesión expirada, inicia sesión nuevamente');
    }

    throw EventException('Error inesperado (${response.statusCode})');
  }

  Future<void> joinEvent(int eventId) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw EventException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw EventException('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$baseUrl/api/events/$eventId/join');

    http.Response response;
    try {
      response = await http
          .post(
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

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 401) {
      throw EventException('Sesión expirada, inicia sesión nuevamente');
    }

    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    final message = decoded is Map<String, dynamic>
        ? decoded['message'] as String? ?? 'No fue posible unirse al evento'
        : 'No fue posible unirse al evento';
    throw EventException(message);
  }
}

class EventException implements Exception {
  EventException(this.message);

  final String message;

  @override
  String toString() => message;
}
