import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService();

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw AuthException('API_BASE_URL no está configurado');
    }

    final uri = Uri.parse('$baseUrl/api/auth/login');

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw AuthException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        throw AuthException('Respuesta inválida del servidor');
      }

      return AuthResponse(token: token, user: AuthUser.fromJson(userData));
    }

    if (response.statusCode == 400 || response.statusCode == 401) {
      throw AuthException('Credenciales inválidas');
    }

    throw AuthException('Error inesperado (${response.statusCode})');
  }
}

class AuthResponse {
  AuthResponse({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.lastName,
    required this.role,
    required this.membership,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      membership: json['membership'] as String? ?? '',
    );
  }

  final int id;
  final String email;
  final String name;
  final String lastName;
  final String role;
  final String membership;
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
