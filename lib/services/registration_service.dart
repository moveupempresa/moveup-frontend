import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/cancelled_reservation.dart';
import '../models/pending_request.dart';
import '../models/registrant.dart';
import '../models/reservation.dart';
import 'auth_service.dart';

class RegistrationService {
  static Future<(String?, int)> signUpForSession({
    required String token,
    required String eventId,
    required String sessionId,
  }) => _request(
    token: token,
    path: 'events/$eventId/sessions/$sessionId/signup',
    method: 'POST',
  );

  static Future<(String?, int)> cancelSessionSignUp({
    required String token,
    required String eventId,
    required String sessionId,
  }) => _request(
    token: token,
    path: 'events/$eventId/sessions/$sessionId/signup',
    method: 'DELETE',
  );

  static Future<(String?, int)> joinSessionWaitlist({
    required String token,
    required String eventId,
    required String sessionId,
  }) => _request(
    token: token,
    path: 'events/$eventId/sessions/$sessionId/waitlist',
    method: 'POST',
  );

  static Future<(String?, int)> leaveSessionWaitlist({
    required String token,
    required String eventId,
    required String sessionId,
  }) => _request(
    token: token,
    path: 'events/$eventId/sessions/$sessionId/waitlist',
    method: 'DELETE',
  );

  static Future<(String?, int)> revokePackRegistration({
    required String token,
    required String eventId,
    required String packId,
    required String userId,
  }) => _request(
    token: token,
    path: 'events/$eventId/packs/$packId/registrations/$userId',
    method: 'DELETE',
  );

  static Future<bool> markSessionAttendance({
    required String token,
    required String eventId,
    required String sessionId,
    required String userId,
    required bool attended,
  }) async {
    http.Response response;
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/events/$eventId/sessions/$sessionId/registrations/$userId/attendance',
      );
      response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'attended': attended}),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return data['attended'] as bool;
  }

  static Future<(String?, int)> signUpForPack({
    required String token,
    required String eventId,
    required String packId,
    List<String>? selectedSessionIds,
  }) => _request(
    token: token,
    path: 'events/$eventId/packs/$packId/signup',
    method: 'POST',
    body: selectedSessionIds != null
        ? {'selectedSessionIds': selectedSessionIds}
        : null,
  );

  static Future<(String?, int)> cancelPackSignUp({
    required String token,
    required String eventId,
    required String packId,
  }) => _request(
    token: token,
    path: 'events/$eventId/packs/$packId/signup',
    method: 'DELETE',
  );

  static Future<(String?, int)> joinPackWaitlist({
    required String token,
    required String eventId,
    required String packId,
  }) => _request(
    token: token,
    path: 'events/$eventId/packs/$packId/waitlist',
    method: 'POST',
  );

  static Future<(String?, int)> leavePackWaitlist({
    required String token,
    required String eventId,
    required String packId,
  }) => _request(
    token: token,
    path: 'events/$eventId/packs/$packId/waitlist',
    method: 'DELETE',
  );

  static Future<(String?, int)> approvePackRequest({
    required String token,
    required String eventId,
    required String packId,
    required String userId,
  }) => _request(
    token: token,
    path: 'events/$eventId/packs/$packId/requests/$userId/approve',
    method: 'POST',
  );

  static Future<(String?, int)> rejectPackRequest({
    required String token,
    required String eventId,
    required String packId,
    required String userId,
  }) => _request(
    token: token,
    path: 'events/$eventId/packs/$packId/requests/$userId/reject',
    method: 'POST',
  );

  static Future<bool> setPackPaymentStatus({
    required String token,
    required String eventId,
    required String packId,
    required String userId,
    required bool hasPaid,
  }) async {
    http.Response response;
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/events/$eventId/packs/$packId/registrations/$userId/payment',
      );
      response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'hasPaid': hasPaid}),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return data['hasPaid'] as bool;
  }

  static Future<bool> payForPack({
    required String token,
    required String eventId,
    required String packId,
  }) async {
    http.Response response;
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/events/$eventId/packs/$packId/payment',
      );
      response = await http
          .post(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return data['hasPaid'] as bool;
  }

  static Future<List<Reservation>> getMyReservations({
    required String token,
  }) async {
    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/users/me/reservations'),
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
    return (data['reservations'] as List<dynamic>)
        .map((r) => Reservation.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CancelledReservation>> getMyCancelledReservations({
    required String token,
  }) async {
    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/users/me/cancelled-reservations'),
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
    return (data['cancellations'] as List<dynamic>)
        .map((c) => CancelledReservation.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  static Future<List<PendingRequest>> getMyPendingRequests({
    required String token,
  }) async {
    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/users/me/pending-requests'),
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
    return (data['requests'] as List<dynamic>)
        .map((r) => PendingRequest.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Registrant>> getSessionRegistrants({
    required String token,
    required String eventId,
    required String sessionId,
  }) => _getRegistrants(
    token: token,
    path: 'events/$eventId/sessions/$sessionId/registrations',
  );

  static Future<List<Registrant>> getPackRegistrants({
    required String token,
    required String eventId,
    required String packId,
  }) => _getRegistrants(
    token: token,
    path: 'events/$eventId/packs/$packId/registrations',
  );

  static Future<List<Registrant>> _getRegistrants({
    required String token,
    required String path,
  }) async {
    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/$path'),
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
    return (data['registrants'] as List<dynamic>)
        .map((r) => Registrant.fromJson(r as Map<String, dynamic>))
        .toList();
  }

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
          ? await http
                .post(uri, headers: headers, body: encodedBody)
                .timeout(const Duration(seconds: 10))
          : await http
                .delete(uri, headers: headers, body: encodedBody)
                .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return (
      data['status'] as String?,
      (data['confirmedCount'] as num?)?.toInt() ?? 0,
    );
  }
}
