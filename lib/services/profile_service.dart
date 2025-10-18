import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackathon_frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  ProfileService();

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  Future<AuthUser> fetchUser(int id) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw ProfileException('API_BASE_URL no está configurado');
    }

    final uri = Uri.parse('$baseUrl/api/users/$id');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null || token.isEmpty) {
      throw ProfileException('Token de autenticación no disponible');
    }

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
      throw ProfileException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthUser.fromJson(data);
    }

    if (response.statusCode == 404) {
      throw ProfileException('Usuario no encontrado');
    }

    throw ProfileException('Error inesperado (${response.statusCode})');
  }

  Future<AuthUser> updateUser({
    required int id,
    required String name,
    required String city,
  }) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw ProfileException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null || token.isEmpty) {
      throw ProfileException('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$baseUrl/api/users/$id');

    http.Response response;
    try {
      response = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': name.trim(),
              'city': city.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw ProfileException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthUser.fromJson(data);
    }

    if (response.statusCode == 400 || response.statusCode == 422) {
      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final message = decoded is Map<String, dynamic>
          ? decoded['message'] as String? ?? 'Datos inválidos'
          : 'Datos inválidos';
      throw ProfileException(message);
    }

    if (response.statusCode == 404) {
      throw ProfileException('Usuario no encontrado');
    }

    throw ProfileException('Error inesperado (${response.statusCode})');
  }
}

class ProfileException implements Exception {
  ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}
