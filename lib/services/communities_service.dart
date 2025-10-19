import 'dart:convert';
import 'dart:developer' as developer;

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
    this.description,
    this.imageUrl,
    this.isPrivate,
    this.createdById,
    this.pendingRequestsDelta = 0,
  });

  factory CommunitySummary.fromJson(Map<String, dynamic> json) {
    final counts = json['_count'] as Map<String, dynamic>?;
    return CommunitySummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      membersCount: counts?['members'] as int? ?? 0,
      eventsCount: counts?['events'] as int? ?? 0,
      requestsCount: counts?['requests'] as int? ?? 0,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isPrivate: json['isPrivate'] as bool?,
      createdById: _parseCreatedById(json),
      pendingRequestsDelta: 0,
    );
  }

  final int id;
  final String name;
  final int membersCount;
  final int eventsCount;
  final int requestsCount;
  final String? description;
  final String? imageUrl;
  final bool? isPrivate;
  final int? createdById;
  final int pendingRequestsDelta;

  static int? _parseCreatedById(Map<String, dynamic> json) {
    final rawCreatedById = json['createdById'];
    if (rawCreatedById is int) {
      return rawCreatedById;
    }
    if (rawCreatedById is num) {
      return rawCreatedById.toInt();
    }
    if (rawCreatedById is String) {
      final parsed = int.tryParse(rawCreatedById);
      if (parsed != null) {
        return parsed;
      }
    }

    final createdByJson = json['createdBy'];
    if (createdByJson is Map<String, dynamic>) {
      final createdByJsonId = createdByJson['id'] ?? createdByJson['userId'];
      if (createdByJsonId is int) {
        return createdByJsonId;
      }
      if (createdByJsonId is num) {
        return createdByJsonId.toInt();
      }
      if (createdByJsonId is String) {
        return int.tryParse(createdByJsonId);
      }
    }

    return null;
  }
}

class CommunityJoinRequestResult {
  CommunityJoinRequestResult({required this.status, this.message});

  final CommunityJoinRequestStatus status;
  final String? message;
}

enum CommunityJoinRequestStatus { success, alreadyRequested }

class CommunityJoinRequest {
  CommunityJoinRequest({
    required this.id,
    this.status,
    this.createdAt,
    this.userName,
    this.userEmail,
  });

  factory CommunityJoinRequest.fromJson(Map<String, dynamic> json) {
    final fromJsonRaw = json['from'] ?? json['user'];
    String? userName;
    String? userEmail;

    if (fromJsonRaw is Map<String, dynamic>) {
      userName = _parseUserName(fromJsonRaw);
      userEmail = _parseUserEmail(fromJsonRaw);
    } else {
      userName = json['userName'] as String?;
      userEmail = json['userEmail'] as String?;
    }

    return CommunityJoinRequest(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      userName: userName,
      userEmail: userEmail,
    );
  }

  final int id;
  final String? status;
  final DateTime? createdAt;
  final String? userName;
  final String? userEmail;

  static String? _parseUserName(Map<String, dynamic> userJson) {
    final firstName = userJson['name'];
    final lastName = userJson['lastName'];
    if (firstName is String && firstName.trim().isNotEmpty) {
      if (lastName is String && lastName.trim().isNotEmpty) {
        return '${firstName.trim()} ${lastName.trim()}';
      }
      return firstName.trim();
    }

    final possibleKeys = ['fullName', 'username', 'displayName'];
    for (final key in possibleKeys) {
      final value = userJson[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final profile = userJson['profile'];
    if (profile is Map<String, dynamic>) {
      final profileName = profile['fullName'] ?? profile['name'];
      if (profileName is String && profileName.trim().isNotEmpty) {
        return profileName.trim();
      }
    }

    return null;
  }

  static String? _parseUserEmail(Map<String, dynamic> userJson) {
    final possibleKeys = ['email', 'emailAddress'];
    for (final key in possibleKeys) {
      final value = userJson[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}

class CommunitiesService {
  CommunitiesService();

  String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://hackathon-back-theta.vercel.app';

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

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    http.Response response;
    try {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw CommunitiesException('No fue posible conectar con el servidor');
    }

    developer.log(
      'fetchCommunities <- status: ${response.statusCode}',
      name: 'CommunitiesService',
    );
    developer.log(
      'fetchCommunities <- body: ${response.body}',
      name: 'CommunitiesService',
    );

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

  Future<CommunityCreationResponse> createCommunity(
    String name,
    String description,
  ) async {
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
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': name.trim(),
              'description': description.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw CommunitiesException('No fue posible conectar con el servidor');
    }

    final decodedBody = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : null;

    developer.log(
      'createCommunity <- status: ${response.statusCode}, body: ${response.body}',
      name: 'CommunitiesService',
    );

    if (response.statusCode == 201) {
      if (decodedBody is! Map<String, dynamic>) {
        throw CommunitiesException('Respuesta inválida del servidor');
      }
      return CommunityCreationResponse.fromJson(decodedBody);
    }

    if (response.statusCode == 400 || response.statusCode == 422) {
      final message = decodedBody is Map<String, dynamic>
          ? decodedBody['message'] as String? ?? 'Datos inválidos'
          : 'Datos inválidos';
      throw CommunitiesException(message);
    }

    if (response.statusCode == 401) {
      throw CommunitiesException('Sesión expirada, inicia sesión nuevamente');
    }

    final errorMessage = decodedBody is Map<String, dynamic>
        ? decodedBody['message'] as String? ??
              'Error inesperado al crear la comunidad'
        : 'Error inesperado al crear la comunidad';
    throw CommunitiesException(errorMessage);
  }

  Future<List<CommunitySummary>> fetchUserCommunities(int userId) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw CommunitiesException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw CommunitiesException('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$baseUrl/api/users/member/$userId');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    http.Response response;
    try {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw CommunitiesException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic>? communitiesJson;

      if (decoded is List) {
        communitiesJson = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final communitiesField = decoded['communities'];
        if (communitiesField is List) {
          communitiesJson = communitiesField;
        }
      }

      if (communitiesJson == null) {
        throw CommunitiesException('Respuesta inválida del servidor');
      }

      return communitiesJson.whereType<Map<String, dynamic>>().map((item) {
        if (item.containsKey('community') &&
            item['community'] is Map<String, dynamic>) {
          return CommunitySummary.fromJson(
            item['community'] as Map<String, dynamic>,
          );
        }
        return CommunitySummary.fromJson(item);
      }).toList();
    }

    if (response.statusCode == 401) {
      throw CommunitiesException('Sesión expirada, inicia sesión nuevamente');
    }

    if (response.statusCode == 404) {
      throw CommunitiesException('Comunidades no encontradas para el usuario');
    }

    throw CommunitiesException('Error inesperado (${response.statusCode})');
  }

  Future<List<CommunityJoinRequest>> fetchCommunityJoinRequests(
    int communityId,
  ) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw CommunitiesException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw CommunitiesException('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$baseUrl/api/communities/$communityId/requests');

    http.Response response;
    try {
      developer.log(
        'fetchCommunityJoinRequests -> GET $uri',
        name: 'CommunitiesService',
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
    } on Exception {
      throw CommunitiesException('No fue posible conectar con el servidor');
    }

    developer.log(
      'fetchCommunityJoinRequests <- status: ${response.statusCode}, body: ${response.body}',
      name: 'CommunitiesService',
    );

    if (response.statusCode == 200) {
      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : [];

      developer.log(
        'fetchCommunityJoinRequests <- decoded=${decoded.runtimeType}: $decoded',
        name: 'CommunitiesService',
      );

      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(CommunityJoinRequest.fromJson)
            .toList();
      }

      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(CommunityJoinRequest.fromJson)
              .toList();
        }
      }

      throw CommunitiesException('Respuesta inválida del servidor');
    }

    if (response.statusCode == 401) {
      throw CommunitiesException('Sesión expirada, inicia sesión nuevamente');
    }

    if (response.statusCode == 404) {
      throw CommunitiesException('Comunidad no encontrada');
    }

    throw CommunitiesException('Error inesperado (${response.statusCode})');
  }

  Future<CommunityJoinRequestResult> requestJoinCommunity(
    int communityId,
  ) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw CommunitiesException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw CommunitiesException('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$baseUrl/api/communities/$communityId/requests');

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
      throw CommunitiesException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      final message = decoded is Map<String, dynamic>
          ? decoded['message'] as String? ?? 'Solicitud enviada correctamente.'
          : 'Solicitud enviada correctamente.';
      return CommunityJoinRequestResult(
        status: CommunityJoinRequestStatus.success,
        message: message,
      );
    }

    if (response.statusCode == 401) {
      throw CommunitiesException('Sesión expirada, inicia sesión nuevamente');
    }

    if (response.statusCode == 409) {
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      final message = decoded is Map<String, dynamic>
          ? decoded['message'] as String? ??
                'Ya cuentas con una solicitud pendiente para esta comunidad.'
          : 'Ya cuentas con una solicitud pendiente para esta comunidad.';
      return CommunityJoinRequestResult(
        status: CommunityJoinRequestStatus.alreadyRequested,
        message: message,
      );
    }

    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    final message = decoded is Map<String, dynamic>
        ? decoded['message'] as String? ??
              'No fue posible enviar la solicitud de ingreso a la comunidad'
        : 'No fue posible enviar la solicitud de ingreso a la comunidad';
    throw CommunitiesException(message);
  }

  Future<CommunityRequestsDelta> approveCommunityJoinRequest({
    required int communityId,
    required int requestId,
  }) async {
    return _processJoinRequestAction(
      communityId: communityId,
      requestId: requestId,
      endpoint: 'approve',
      successMessage: 'Solicitud aprobada',
    );
  }

  Future<CommunityRequestsDelta> rejectCommunityJoinRequest({
    required int communityId,
    required int requestId,
  }) async {
    return _processJoinRequestAction(
      communityId: communityId,
      requestId: requestId,
      endpoint: 'reject',
      successMessage: 'Solicitud rechazada',
    );
  }

  Future<CommunityRequestsDelta> _processJoinRequestAction({
    required int communityId,
    required int requestId,
    required String endpoint,
    required String successMessage,
  }) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw CommunitiesException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw CommunitiesException('Token de autenticación no disponible');
    }

    final uri = Uri.parse(
      '$baseUrl/api/communities/$communityId/requests/$requestId/$endpoint',
    );

    http.Response response;
    try {
      developer.log(
        '_processJoinRequestAction -> POST $uri',
        name: 'CommunitiesService',
      );
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
      throw CommunitiesException('No fue posible conectar con el servidor');
    }

    developer.log(
      '_processJoinRequestAction <- status: ${response.statusCode}, body: ${response.body}',
      name: 'CommunitiesService',
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final requestsRemaining = decoded is Map<String, dynamic>
          ? decoded['pendingRequests'] as int?
          : null;
      return CommunityRequestsDelta(
        communityId: communityId,
        pendingRequests: requestsRemaining,
      );
    }

    if (response.statusCode == 401) {
      throw CommunitiesException('Sesión expirada, inicia sesión nuevamente');
    }

    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    final message = decoded is Map<String, dynamic>
        ? (decoded['message'] as String?) ??
            (decoded['error'] as String?) ??
            successMessage
        : successMessage;

    throw CommunitiesException(message);
  }
}

class CommunityRequestsDelta {
  CommunityRequestsDelta({
    required this.communityId,
    this.pendingRequests,
  });

  final int communityId;
  final int? pendingRequests;
}

class CommunityCreationResponse {
  CommunityCreationResponse({required this.message, required this.community});

  factory CommunityCreationResponse.fromJson(Map<String, dynamic> json) {
    final communityJson = json['community'];
    if (communityJson is! Map<String, dynamic>) {
      throw CommunitiesException('Respuesta inválida del servidor');
    }

    return CommunityCreationResponse(
      message: json['message'] as String? ?? 'Comunidad creada exitosamente',
      community: CreatedCommunity.fromJson(communityJson),
    );
  }

  final String message;
  final CreatedCommunity community;
}

class CreatedCommunity {
  CreatedCommunity({required this.id, required this.name, required this.description});

  factory CreatedCommunity.fromJson(Map<String, dynamic> json) {
    return CreatedCommunity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  final int id;
  final String name;
  final String description;
}

class CommunityDetail {
  CommunityDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.membersCount,
    required this.eventsCount,
    required this.requestsCount,
    this.createdById,
    this.imageUrl,
    this.members,
    this.events,
  });

  factory CommunityDetail.fromJson(Map<String, dynamic> json) {
    final counts = json['_count'] as Map<String, dynamic>?;
    final createdById = CommunitySummary._parseCreatedById(json);
    return CommunityDetail(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      membersCount: counts?['members'] as int? ?? 0,
      eventsCount: counts?['events'] as int? ?? 0,
      requestsCount: counts?['requests'] as int? ?? 0,
      createdById: createdById,
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
  final int? createdById;
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
