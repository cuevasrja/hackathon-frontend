import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService();

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://hackathon-back-theta.vercel.app';

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final baseUrl = _baseUrl.trim();
    developer.log('[AuthService] baseUrl: ' + baseUrl);
    if (baseUrl.isEmpty) {
      throw AuthException('API_BASE_URL no está configurado');
    }

    final uri = Uri.parse('$baseUrl/api/auth/login');
    developer.log('[AuthService] uri: ' + uri.toString());

    http.Response response;
    try {
      developer.log('[AuthService] Enviando POST a: ' + uri.toString());
      developer.log('[AuthService] Headers: ' + jsonEncode({'Content-Type': 'application/json'}));
      developer.log('[AuthService] Body: ' + jsonEncode({'email': email, 'password': password}));
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
      developer.log('[AuthService] Response status: ' + response.statusCode.toString());
      developer.log('[AuthService] Response body: ' + response.body);
    } on Exception catch (e, st) {
      developer.log('[AuthService] Exception: ' + e.toString(),
          error: e, stackTrace: st);
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

  Future<AuthResponse> signup({
    required String name,
    required String lastName,
    required String email,
    required String password,
    required String birthDate,
    required String gender,
    required String city,
    required String country,
  // File? documentFrontImage, // document upload disabled
  }) async {
    final baseUrl = _baseUrl.trim();
    developer.log('[AuthService] signup baseUrl: ' + baseUrl);
    if (baseUrl.isEmpty) {
      throw AuthException('API_BASE_URL no está configurado');
    }

    final uri = Uri.parse('$baseUrl/api/auth/signup');
    developer.log('[AuthService] signup uri: ' + uri.toString());

    // Identity document upload disabled; build payload without document
    http.Response response;
    final payload = <String, dynamic>{
      'name': name,
      'lastName': lastName,
      'email': email,
      'password': password,
      'birthDate': birthDate,
      'gender': gender,
      'city': city,
      'country': country,
      // documentFrontImage and image fields removed
    };
    developer.log('[AuthService] signup payload keys: ' + payload.keys.join(', '));
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));
      developer.log('[AuthService] signup response status: ' + response.statusCode.toString());
      developer.log('[AuthService] signup response body: ' + response.body);
    } on Exception catch (e, st) {
      developer.log('[AuthService] signup Exception: ' + e.toString(), error: e, stackTrace: st);
      throw AuthException('No fue posible conectar con el servidor');
    }

    developer.log('[AuthService] signup final status: ' + response.statusCode.toString());
    developer.log('[AuthService] signup final body: ' + response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          developer.log('[AuthService] signup decoded data: ' + data.toString());
          final token = data['token'] as String?;
          final userData = data['user'] as Map<String, dynamic>?;

          if (token != null && userData != null) {
            return AuthResponse(
              token: token,
              user: AuthUser.fromJson(userData),
            );
          }
        } on FormatException catch (e, st) {
          developer.log('[AuthService] signup FormatException: ' + e.toString(), error: e, stackTrace: st);
          throw AuthException('Respuesta de signup no es JSON');
        }
      }

      return await login(email: email, password: password);
    }

    if (response.statusCode == 400 || response.statusCode == 409) {
      developer.log('[AuthService] signup error: No fue posible registrar la cuenta');
      throw AuthException('No fue posible registrar la cuenta');
    }

    developer.log('[AuthService] signup error inesperado: ' + response.statusCode.toString());
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
    required this.city,
    this.image,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      membership: json['membership'] as String? ?? '',
      city: json['city'] as String? ?? '',
      image: json['image'] as String?,
    );
  }

  final int id;
  final String email;
  final String name;
  final String lastName;
  final String role;
  final String membership;
  final String city;
  final String? image;
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
