import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/session.dart';
import 'auth_service.dart';

class SessionService {
  static Future<Session> createSession({
    required String token,
    required String eventId,
    required String name,
    required DateTime startDatetime,
    required DateTime endDatetime,
    required String address,
    required bool isUnlimitedCapacity,
    int? capacity,
  }) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/events/$eventId/sessions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': name,
              'startDatetime': startDatetime.toUtc().toIso8601String(),
              'endDatetime': endDatetime.toUtc().toIso8601String(),
              'address': address,
              'isUnlimitedCapacity': isUnlimitedCapacity,
              if (!isUnlimitedCapacity && capacity != null) 'capacity': capacity,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return Session.fromJson(data['session'] as Map<String, dynamic>);
  }

  static Future<Session> updateSession({
    required String token,
    required String eventId,
    required String sessionId,
    required String name,
    required DateTime startDatetime,
    required DateTime endDatetime,
    required String address,
    required bool isUnlimitedCapacity,
    int? capacity,
  }) async {
    http.Response response;
    try {
      response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/events/$eventId/sessions/$sessionId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': name,
              'startDatetime': startDatetime.toUtc().toIso8601String(),
              'endDatetime': endDatetime.toUtc().toIso8601String(),
              'address': address,
              'isUnlimitedCapacity': isUnlimitedCapacity,
              if (!isUnlimitedCapacity && capacity != null) 'capacity': capacity,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return Session.fromJson(data['session'] as Map<String, dynamic>);
  }

  static Future<void> deleteSession({
    required String token,
    required String eventId,
    required String sessionId,
  }) async {
    http.Response response;
    try {
      response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/events/$eventId/sessions/$sessionId'),
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

  static Future<List<Session>> getEventSessions({
    required String token,
    required String eventId,
  }) async {
    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/events/$eventId/sessions'),
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
    return (data['sessions'] as List<dynamic>)
        .map((s) => Session.fromJson(s as Map<String, dynamic>))
        .toList();
  }
}
