import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PlacesService {
  PlacesService();

  String get _baseUrl => "https://hackathon-back-theta.vercel.app";

  Future<PlacesResponse> fetchPlaces({
    String? city,
    String? country,
    String? type,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw PlacesException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw PlacesException('Token de autenticación no disponible');
    }

    final queryParameters = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (city != null && city.trim().isNotEmpty) {
      queryParameters['city'] = city.trim();
    }
    if (country != null && country.trim().isNotEmpty) {
      queryParameters['country'] = country.trim();
    }
    if (type != null && type.trim().isNotEmpty) {
      queryParameters['type'] = type.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      queryParameters['status'] = status.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/api/places',
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
      throw PlacesException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw PlacesException('Respuesta inválida del servidor');
      }

      final data = decoded['data'];
      final pagination = decoded['pagination'];
      if (data is! List) {
        throw PlacesException('Respuesta inválida del servidor');
      }

      final places = data
          .whereType<Map<String, dynamic>>()
          .map((json) => PlaceSummary.fromJson(json))
          .toList();

      final paginationInfo = PlacePagination.fromJson(
        pagination is Map<String, dynamic> ? pagination : <String, dynamic>{},
      );

      return PlacesResponse(places: places, pagination: paginationInfo);
    }

    if (response.statusCode == 401) {
      throw PlacesException('Sesión expirada, inicia sesión nuevamente');
    }

    throw PlacesException('Error inesperado (${response.statusCode})');
  }

  Future<PlaceCreationResponse> createPlace({
    required String name,
    required String direction,
    required String city,
    required String country,
    required int capacity,
    required String type,
    required int proprietorId,
    required String mapUrl,
    required String image,
  }) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw PlacesException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw PlacesException('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$baseUrl/api/places');

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
              'direction': direction.trim(),
              'city': city.trim(),
              'country': country.trim(),
              'capacity': capacity,
              'type': type.trim(),
              'proprietorId': proprietorId,
              'mapUrl': mapUrl.trim(),
              'image': image.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw PlacesException('No fue posible conectar con el servidor');
    }

    final decodedBody = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : null;

    if (response.statusCode == 201) {
      if (decodedBody is! Map<String, dynamic>) {
        throw PlacesException('Respuesta inválida del servidor');
      }
      return PlaceCreationResponse.fromJson(decodedBody);
    }

    if (response.statusCode == 400 || response.statusCode == 422) {
      final message = decodedBody is Map<String, dynamic>
          ? decodedBody['message'] as String? ?? 'Datos inválidos'
          : 'Datos inválidos';
      throw PlacesException(message);
    }

    if (response.statusCode == 401) {
      throw PlacesException('Sesión expirada, inicia sesión nuevamente');
    }

    if (decodedBody is Map<String, dynamic>) {
      final message =
          decodedBody['message'] as String? ??
          'Error inesperado al crear el negocio';
      throw PlacesException(message);
    }

    throw PlacesException('Error inesperado (${response.statusCode})');
  }
}

class PlacesResponse {
  PlacesResponse({required this.places, required this.pagination});

  final List<PlaceSummary> places;
  final PlacePagination pagination;
}

class PlaceSummary {
  PlaceSummary({
    required this.id,
    required this.name,
    required this.direction,
    required this.city,
    required this.country,
    required this.capacity,
    required this.type,
    required this.status,
    required this.productsCount,
    required this.eventsCount,
    required this.reviewsCount,
    this.imageUrl,
    this.proprietor,
    this.ownerId,
  });

  factory PlaceSummary.fromJson(Map<String, dynamic> json) {
    final proprietorJson = json['proprietor'];
    final countsJson = json['_count'];
    final images = json['images'];

    String? resolvedImage;
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String) {
        resolvedImage = first;
      } else if (first is Map<String, dynamic>) {
        resolvedImage = first['url'] as String? ?? first['imageUrl'] as String?;
      }
    }
    resolvedImage ??= json['imageUrl'] as String?;

    return PlaceSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      direction: json['direction'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      capacity: json['capacity'] is int
          ? json['capacity'] as int
          : int.tryParse('${json['capacity']}') ?? 0,
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      productsCount: countsJson is Map<String, dynamic>
          ? countsJson['products'] as int? ?? 0
          : 0,
      eventsCount: countsJson is Map<String, dynamic>
          ? countsJson['events'] as int? ?? 0
          : 0,
      reviewsCount: countsJson is Map<String, dynamic>
          ? countsJson['reviews'] as int? ?? 0
          : 0,
      imageUrl: resolvedImage,
      proprietor: proprietorJson is Map<String, dynamic>
          ? PlaceProprietor.fromJson(proprietorJson)
          : null,
      ownerId: json['ownerId'] is int
          ? json['ownerId'] as int
          : int.tryParse('${json['ownerId']}'),
    );
  }

  final int id;
  final String name;
  final String direction;
  final String city;
  final String country;
  final int capacity;
  final String type;
  final String status;
  final int productsCount;
  final int eventsCount;
  final int reviewsCount;
  final String? imageUrl;
  final PlaceProprietor? proprietor;
  final int? ownerId;

  String get proprietorFullName {
    if (proprietor == null) {
      return 'Sin propietario asignado';
    }
    return proprietor!.fullName;
  }
}

class PlaceProprietor {
  PlaceProprietor({
    required this.id,
    required this.name,
    required this.lastName,
  });

  factory PlaceProprietor.fromJson(Map<String, dynamic> json) {
    return PlaceProprietor(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
    );
  }

  final int id;
  final String name;
  final String lastName;

  String get fullName {
    final trimmed = '$name $lastName'.trim();
    return trimmed.isEmpty ? 'Propietario sin nombre' : trimmed;
  }
}

class PlacePagination {
  PlacePagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PlacePagination.fromJson(Map<String, dynamic> json) {
    return PlacePagination(
      page: json['page'] is int
          ? json['page'] as int
          : int.tryParse('${json['page']}') ?? 1,
      limit: json['limit'] is int
          ? json['limit'] as int
          : int.tryParse('${json['limit']}') ?? 10,
      total: json['total'] is int
          ? json['total'] as int
          : int.tryParse('${json['total']}') ?? 0,
      totalPages: json['totalPages'] is int
          ? json['totalPages'] as int
          : int.tryParse('${json['totalPages']}') ?? 1,
    );
  }

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

class PlaceCreationResponse {
  PlaceCreationResponse({required this.message, required this.place});

  factory PlaceCreationResponse.fromJson(Map<String, dynamic> json) {
    final placeJson = json['place'];
    if (placeJson is! Map<String, dynamic>) {
      throw PlacesException('Respuesta inválida del servidor');
    }
    return PlaceCreationResponse(
      message: json['message'] as String? ?? 'Negocio creado exitosamente',
      place: PlaceSummary.fromJson(placeJson),
    );
  }

  final String message;
  final PlaceSummary place;
}

class PlacesException implements Exception {
  PlacesException(this.message);

  final String message;

  @override
  String toString() => message;
}
