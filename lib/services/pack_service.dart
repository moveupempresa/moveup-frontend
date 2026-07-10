import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/pack.dart';
import 'auth_service.dart';

class PackService {
  static Future<Pack> createPack({
    required String token,
    required String eventId,
    required String name,
    String? description,
    required double price,
    required PaymentType paymentType,
    required PackType packType,
    required ApprovalMode approvalMode,
    int? maxSelectableSessions,
    required bool isUnlimitedCapacity,
    int? capacity,
    List<String> sessionIds = const [],
  }) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/events/$eventId/packs'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': name,
              if (description != null) 'description': description,
              'price': price,
              'paymentType': paymentType.value,
              'packType': packType.value,
              'approvalMode': approvalMode.value,
              if (maxSelectableSessions != null) 'maxSelectableSessions': maxSelectableSessions,
              'isUnlimitedCapacity': isUnlimitedCapacity,
              if (!isUnlimitedCapacity && capacity != null) 'capacity': capacity,
              if (sessionIds.isNotEmpty) 'sessionIds': sessionIds,
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
    return Pack.fromJson(data['pack'] as Map<String, dynamic>);
  }

  static Future<Pack> updatePack({
    required String token,
    required String eventId,
    required String packId,
    required String name,
    String? description,
    required double price,
    required PaymentType paymentType,
    required PackType packType,
    required ApprovalMode approvalMode,
    int? maxSelectableSessions,
    required bool isUnlimitedCapacity,
    int? capacity,
    List<String> sessionIds = const [],
  }) async {
    http.Response response;
    try {
      response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/events/$eventId/packs/$packId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': name,
              'description': description,
              'price': price,
              'paymentType': paymentType.value,
              'packType': packType.value,
              'approvalMode': approvalMode.value,
              'maxSelectableSessions': maxSelectableSessions,
              'isUnlimitedCapacity': isUnlimitedCapacity,
              'capacity': isUnlimitedCapacity ? null : capacity,
              'sessionIds': sessionIds,
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
    return Pack.fromJson(data['pack'] as Map<String, dynamic>);
  }

  static Future<void> deletePack({
    required String token,
    required String eventId,
    required String packId,
  }) async {
    http.Response response;
    try {
      response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/events/$eventId/packs/$packId'),
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

  static Future<List<Pack>> getEventPacks({
    required String token,
    required String eventId,
  }) async {
    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/events/$eventId/packs'),
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
    return (data['packs'] as List<dynamic>)
        .map((p) => Pack.fromJson(p as Map<String, dynamic>))
        .toList();
  }
}
