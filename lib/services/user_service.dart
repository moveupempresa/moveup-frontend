import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/user.dart';
import 'auth_service.dart';

class UserService {
  static Future<User> changeUsername({
    required String token,
    required String username,
  }) async {
    http.Response response;
    try {
      response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/users/me/username'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'username': username}),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  static Future<void> requestEmailChange({
    required String token,
    required String newEmail,
  }) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/users/me/request-email-change'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'newEmail': newEmail}),
          )
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
  }

  static Future<User> confirmEmailChange({
    required String token,
    required String code,
  }) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/users/me/confirm-email-change'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'code': code}),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  static Future<void> deleteAccount({required String token}) async {
    http.Response response;
    try {
      response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/users/me'),
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

  static Future<User> upgradeToPro({required String token}) =>
      _planRequest(token: token, endpoint: 'upgrade-to-pro');

  static Future<User> downgradeToFree({required String token}) =>
      _planRequest(token: token, endpoint: 'downgrade-to-free');

  static Future<User> _planRequest({
    required String token,
    required String endpoint,
  }) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/users/$endpoint'),
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
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }
}
