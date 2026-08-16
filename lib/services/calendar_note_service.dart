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

  static Future<CalendarNote> setDayNote({
    required String token,
    required String date,
    required String text,
  }) => _putNote(token: token, date: date, body: {'text': text});

  static Future<CalendarNote> setEventNote({
    required String token,
    required String date,
    required int hour,
    required String title,
    String? address,
    int startMinute = 0,
    required int endHour,
    int endMinute = 0,
  }) => _putNote(
    token: token,
    date: date,
    hour: hour,
    body: {
      'title': title,
      if (address != null && address.isNotEmpty) 'address': address,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
    },
  );

  static Future<CalendarNote> _putNote({
    required String token,
    required String date,
    required Map<String, dynamic> body,
    int? hour,
  }) async {
    http.Response response;
    try {
      response = await http
          .put(
            Uri.parse(
              '${ApiConfig.baseUrl}/users/me/calendar-notes/$date',
            ).replace(queryParameters: hour != null ? {'hour': '$hour'} : null),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
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
    return CalendarNote.fromJson(data['note'] as Map<String, dynamic>);
  }

  static Future<void> deleteNote({
    required String token,
    required String date,
    int? hour,
  }) async {
    http.Response response;
    try {
      response = await http
          .delete(
            Uri.parse(
              '${ApiConfig.baseUrl}/users/me/calendar-notes/$date',
            ).replace(queryParameters: hour != null ? {'hour': '$hour'} : null),
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
