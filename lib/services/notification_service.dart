import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hackathon_frontend/models/notification_model.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService();

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://hackathon-back-theta.vercel.app';

  Future<http.Response> _makeAuthenticatedRequest(Future<http.Response> Function(Map<String, String>) request) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(LoginStorageKeys.token);
    if (token == null || token.isEmpty) {
      throw Exception('Token de autenticación no disponible');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    return request(headers);
  }

  Future<List<Notification>> fetchNotifications() async {
    final url = Uri.parse('$_baseUrl/api/notifications');
    final response = await _makeAuthenticatedRequest((headers) => http.get(url, headers: headers));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Notification.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> markAllAsRead() async {
    final url = Uri.parse('$_baseUrl/api/notifications/mark-all-read');
    final response = await _makeAuthenticatedRequest((headers) => http.put(url, headers: headers));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to mark all notifications as read');
    }
  }
}