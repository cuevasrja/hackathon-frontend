import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductsService {
  ProductsService();

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  Future<List<ProductSummary>> fetchProducts({
    required int placeId,
    double? minPrice,
    double? maxPrice,
  }) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw ProductsException('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw ProductsException('Token de autenticación no disponible');
    }

    final queryParameters = <String, String>{
      'placeId': placeId.toString(),
    };

    if (minPrice != null) {
      queryParameters['minPrice'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParameters['maxPrice'] = maxPrice.toString();
    }

    final uri = Uri.parse('$baseUrl/api/products').replace(
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
      throw ProductsException('No fue posible conectar con el servidor');
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw ProductsException('Respuesta inválida del servidor');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((json) => ProductSummary.fromJson(json))
          .toList();
    }

    if (response.statusCode == 401) {
      throw ProductsException('Sesión expirada, inicia sesión nuevamente');
    }

    throw ProductsException('Error inesperado (${response.statusCode})');
  }
}

class ProductSummary {
  ProductSummary({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    this.promotions = const [],
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    final promotionsJson = json['promotions'];

    return ProductSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      price: double.tryParse('${json['price']}') ?? 0,
      image: json['image'] as String?,
      promotions: promotionsJson is List
          ? promotionsJson
              .whereType<Map<String, dynamic>>()
              .map(ProductPromotion.fromJson)
              .toList()
          : const [],
    );
  }

  final int id;
  final String name;
  final double price;
  final String? image;
  final List<ProductPromotion> promotions;

  String get formattedPrice => 'Bs. ${price.toStringAsFixed(2)}';
}

class ProductPromotion {
  ProductPromotion({
    required this.id,
    required this.discount,
    required this.membership,
  });

  factory ProductPromotion.fromJson(Map<String, dynamic> json) {
    return ProductPromotion(
      id: json['id'] as int,
      discount: json['discount'] is int
          ? json['discount'] as int
          : int.tryParse('${json['discount']}') ?? 0,
      membership: json['membership'] as String? ?? '',
    );
  }

  final int id;
  final int discount;
  final String membership;
}

class ProductsException implements Exception {
  ProductsException(this.message);

  final String message;

  @override
  String toString() => message;
}
