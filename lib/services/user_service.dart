import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/popular_profile.dart';
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

  static Future<List<PopularProfile>> getMyFollowing({required String token}) async {
    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/users/me/following'),
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
    return (data['profiles'] as List<dynamic>)
        .map((p) => PopularProfile.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  static Future<(bool, int)> followUser({
    required String token,
    required String userId,
  }) =>
      _followRequest(token: token, userId: userId, unfollow: false);

  static Future<(bool, int)> unfollowUser({
    required String token,
    required String userId,
  }) =>
      _followRequest(token: token, userId: userId, unfollow: true);

  static Future<(bool, int)> _followRequest({
    required String token,
    required String userId,
    required bool unfollow,
  }) async {
    http.Response response;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/users/$userId/follow');
      final headers = {'Authorization': 'Bearer $token'};
      response = unfollow
          ? await http.delete(uri, headers: headers).timeout(const Duration(seconds: 10))
          : await http.post(uri, headers: headers).timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return (data['isFollowing'] as bool, data['followersCount'] as int);
  }

  static Future<User> upgradeToPro({
    required String token,
    required String accountHolderName,
    required String iban,
  }) =>
      _planRequest(
        token: token,
        endpoint: 'upgrade-to-pro',
        body: {'accountHolderName': accountHolderName, 'iban': iban},
      );

  static Future<User> downgradeToFree({required String token}) =>
      _planRequest(token: token, endpoint: 'downgrade-to-free');

  static Future<User> _planRequest({
    required String token,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/users/$endpoint'),
            headers: {
              'Authorization': 'Bearer $token',
              if (body != null) 'Content-Type': 'application/json',
            },
            body: body != null ? jsonEncode(body) : null,
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
