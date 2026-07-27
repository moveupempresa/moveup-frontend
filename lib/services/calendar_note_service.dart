import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/calendar_note.dart';
import 'auth_service.dart';

class CalendarNoteService {
  static Future<List<CalendarNote>> getMyNotes({required String token}) async {
    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/users/me/calendar-notes'),
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
    return (data['notes'] as List<dynamic>)
        .map((n) => CalendarNote.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  static Future<CalendarNote> setNote({
    required String token,
    required String date,
    required String text,
  }) async {
    http.Response response;
    try {
      response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/users/me/calendar-notes/$date'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return CalendarNote.fromJson(data['note'] as Map<String, dynamic>);
  }

  static Future<void> deleteNote({required String token, required String date}) async {
    http.Response response;
    try {
      response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/users/me/calendar-notes/$date'),
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
