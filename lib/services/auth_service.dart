import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/profile.dart';
import '../models/user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthResult {
  final String token;
  final User user;
  final Profile profile;

  AuthResult({required this.token, required this.user, required this.profile});
}

class AuthService {
  static Future<AuthResult> signin({
    required String email,
    required String password,
  }) {
    return _authRequest('signin', {'email': email, 'password': password});
  }

  static Future<AuthResult> signup({
    required String email,
    required String username,
    required String password,
  }) {
    return _authRequest('signup', {
      'email': email,
      'username': username,
      'password': password,
    });
  }

  static Future<void> forgotPassword({required String email}) async {
    await _postRequest('forgot-password', {'email': email});
  }

  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _postRequest('reset-password', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  static Future<AuthResult> _authRequest(
    String endpoint,
    Map<String, String> body,
  ) async {
    final data = await _postRequest(endpoint, body);
    return AuthResult(
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      profile: Profile.fromJson(data['profile'] as Map<String, dynamic>),
    );
  }

  static Future<Map<String, dynamic>> _postRequest(
    String endpoint,
    Map<String, String> body,
  ) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }

    return data;
  }
}
