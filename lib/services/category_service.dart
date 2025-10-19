import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackathon_frontend/models/category_model.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  CategoryService();

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://hackathon-back-theta.vercel.app';

  Future<List<Category>> fetchCategories() async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('API_BASE_URL no está configurado');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw Exception('Token de autenticación no disponible');
    }

    final uri = Uri.parse('$_baseUrl/api/categories');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Category.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }
}
