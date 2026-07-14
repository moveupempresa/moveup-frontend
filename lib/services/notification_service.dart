import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/app_notification.dart';
import 'auth_service.dart';

class NotificationService {
  static Future<List<AppNotification>> getMyNotifications({required String token}) async {
    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/notifications'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return (data['notifications'] as List<dynamic>)
        .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markAllAsRead({required String token}) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/notifications/mark-read'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
  }
}
