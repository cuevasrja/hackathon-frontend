import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CommunitySummary {
  CommunitySummary({
    required this.id,
    required this.name,
    required this.membersCount,
    required this.eventsCount,
    required this.requestsCount,
  });

  factory CommunitySummary.fromJson(Map<String, dynamic> json) {
    final counts = json['_count'] as Map<String, dynamic>?;
    return CommunitySummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      membersCount: counts?['members'] as int? ?? 0,
      eventsCount: counts?['events'] as int? ?? 0,
      requestsCount: counts?['requests'] as int? ?? 0,
    );
  }

  final int id;
  final String name;
  final int membersCount;
  final int eventsCount;
  final int requestsCount;
}

class CommunitiesService {
  CommunitiesService();

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  Future<List<CommunitySummary>> fetchCommunities() async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw CommunitiesException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw CommunitiesException('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$baseUrl/api/communities');

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
      throw CommunitiesException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw CommunitiesException('Respuesta inválida del servidor');
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CommunitySummary.fromJson)
          .toList();
    }

    if (response.statusCode == 401) {
      throw CommunitiesException('Sesión expirada, inicia sesión nuevamente');
    }

    throw CommunitiesException('Error inesperado (${response.statusCode})');
  }

  Future<CommunityDetail> fetchCommunityDetail(int id) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw CommunitiesException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw CommunitiesException('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$baseUrl/api/communities/$id');

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
      throw CommunitiesException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw CommunitiesException('Respuesta inválida del servidor');
      }
      return CommunityDetail.fromJson(decoded);
    }

    if (response.statusCode == 404) {
      throw CommunitiesException('Comunidad no encontrada');
    }

    throw CommunitiesException('Error inesperado (${response.statusCode})');
  }
}

class CommunityDetail {
  CommunityDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.membersCount,
    required this.eventsCount,
    required this.requestsCount,
    this.imageUrl,
    this.members,
    this.events,
  });

  factory CommunityDetail.fromJson(Map<String, dynamic> json) {
    final counts = json['_count'] as Map<String, dynamic>?;
    return CommunityDetail(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      membersCount: counts?['members'] as int? ?? 0,
      eventsCount: counts?['events'] as int? ?? 0,
      requestsCount: counts?['requests'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String?,
      members: json['members'] as List<dynamic>?,
      events: json['events'] as List<dynamic>?,
    );
  }

  final int id;
  final String name;
  final String description;
  final int membersCount;
  final int eventsCount;
  final int requestsCount;
  final String? imageUrl;
  final List<dynamic>? members;
  final List<dynamic>? events;
}

class CommunitiesException implements Exception {
  CommunitiesException(this.message);

  final String message;

  @override
  String toString() => message;
}
