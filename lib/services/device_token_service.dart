import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class DeviceTokenService {
  static Future<void> register({
    required String token,
    required String deviceToken,
    required String platform,
  }) async {
    http.Response response;
    try {
      response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/users/me/device-token'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'token': deviceToken, 'platform': platform}),
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

  static Future<void> unregister({
    required String token,
    required String deviceToken,
  }) async {
    http.Response response;
    try {
      response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/users/me/device-token'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'token': deviceToken}),
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
