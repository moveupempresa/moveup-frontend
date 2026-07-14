import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class RegistrationService {
  static Future<(String?, int)> signUpForSession({
    required String token,
    required String eventId,
    required String sessionId,
  }) =>
      _request(
        token: token,
        path: 'events/$eventId/sessions/$sessionId/signup',
        method: 'POST',
      );

  static Future<(String?, int)> cancelSessionSignUp({
    required String token,
    required String eventId,
    required String sessionId,
  }) =>
      _request(
        token: token,
        path: 'events/$eventId/sessions/$sessionId/signup',
        method: 'DELETE',
      );

  static Future<(String?, int)> joinSessionWaitlist({
    required String token,
    required String eventId,
    required String sessionId,
  }) =>
      _request(
        token: token,
        path: 'events/$eventId/sessions/$sessionId/waitlist',
        method: 'POST',
      );

  static Future<(String?, int)> leaveSessionWaitlist({
    required String token,
    required String eventId,
    required String sessionId,
  }) =>
      _request(
        token: token,
        path: 'events/$eventId/sessions/$sessionId/waitlist',
        method: 'DELETE',
      );

  static Future<(String?, int)> signUpForPack({
    required String token,
    required String eventId,
    required String packId,
    List<String>? selectedSessionIds,
  }) =>
      _request(
        token: token,
        path: 'events/$eventId/packs/$packId/signup',
        method: 'POST',
        body: selectedSessionIds != null ? {'selectedSessionIds': selectedSessionIds} : null,
      );

  static Future<(String?, int)> cancelPackSignUp({
    required String token,
    required String eventId,
    required String packId,
  }) =>
      _request(
        token: token,
        path: 'events/$eventId/packs/$packId/signup',
        method: 'DELETE',
      );

  static Future<(String?, int)> joinPackWaitlist({
    required String token,
    required String eventId,
    required String packId,
  }) =>
      _request(
        token: token,
        path: 'events/$eventId/packs/$packId/waitlist',
        method: 'POST',
      );

  static Future<(String?, int)> leavePackWaitlist({
    required String token,
    required String eventId,
    required String packId,
  }) =>
      _request(
        token: token,
        path: 'events/$eventId/packs/$packId/waitlist',
        method: 'DELETE',
      );

  static Future<(String?, int)> approvePackRequest({
    required String token,
    required String eventId,
    required String packId,
    required String userId,
  }) =>
      _request(
        token: token,
        path: 'events/$eventId/packs/$packId/requests/$userId/approve',
        method: 'POST',
      );

  static Future<(String?, int)> rejectPackRequest({
    required String token,
    required String eventId,
    required String packId,
    required String userId,
  }) =>
      _request(
        token: token,
        path: 'events/$eventId/packs/$packId/requests/$userId/reject',
        method: 'POST',
      );

  static Future<(String?, int)> _request({
    required String token,
    required String path,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    http.Response response;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/$path');
      final headers = {
        'Authorization': 'Bearer $token',
        if (body != null) 'Content-Type': 'application/json',
      };
      final encodedBody = body != null ? jsonEncode(body) : null;
      response = method == 'POST'
          ? await http.post(uri, headers: headers, body: encodedBody).timeout(const Duration(seconds: 10))
          : await http.delete(uri, headers: headers, body: encodedBody).timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return (data['status'] as String?, (data['confirmedCount'] as num?)?.toInt() ?? 0);
  }
}
