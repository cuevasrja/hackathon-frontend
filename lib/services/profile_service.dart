import 'dart:convert';
import 'dart:developer' as developer;

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
      developer.log(
        'Solicitando perfil de usuario $id a ${uri.toString()}',
        name: 'ProfileService',
      );
      developer.log(
        'Headers enviados: {Content-Type: application/json, Authorization: Bearer $token}',
        name: 'ProfileService',
      );
      response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));
      developer.log(
        'Respuesta perfil código ${response.statusCode}: ${response.body}',
        name: 'ProfileService',
      );
    } on Exception {
      developer.log(
        'Error de red al solicitar perfil de usuario $id',
        name: 'ProfileService',
        error: 'network',
      );
      throw ProfileException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthUser.fromJson(data);
    }

    if (response.statusCode == 404) {
      developer.log('Usuario $id no encontrado (404)', name: 'ProfileService');
      throw ProfileException('Usuario no encontrado');
    }

    developer.log(
      'Error inesperado al solicitar perfil (${response.statusCode})',
      name: 'ProfileService',
    );
    throw ProfileException('Error inesperado (${response.statusCode})');
  }
}

class ProfileException implements Exception {
  ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}
