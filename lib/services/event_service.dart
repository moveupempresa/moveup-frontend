import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../models/event.dart';
import 'auth_service.dart';

class EventService {
  static Future<Event> createEvent({
    required String token,
    required String title,
    required String description,
    required List<String> style,
    required String city,
    required String country,
    required File coverFile,
    bool reservationEnabled = false,
    EventStatus status = EventStatus.draft,
  }) async {
    http.Response response;
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/events'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['style'] = jsonEncode(style);
      request.fields['city'] = city;
      request.fields['country'] = country;
      request.fields['reservationEnabled'] = reservationEnabled.toString();
      request.fields['status'] = status.value;

      request.files.add(await http.MultipartFile.fromPath(
        'cover',
        coverFile.path,
        contentType: _mediaTypeFromPath(coverFile.path),
      ));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return Event.fromJson(data['event'] as Map<String, dynamic>);
  }

  static Future<Event> updateEvent({
    required String token,
    required String eventId,
    String? title,
    String? description,
    List<String>? style,
    String? city,
    String? country,
    File? coverFile,
    bool? reservationEnabled,
    EventType? eventType,
    LocationType? locationType,
    EventVisibility? visibility,
    EventStatus? status,
  }) async {
    http.Response response;
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiConfig.baseUrl}/events/$eventId'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      if (title != null) request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      if (style != null) request.fields['style'] = jsonEncode(style);
      if (city != null) request.fields['city'] = city;
      if (country != null) request.fields['country'] = country;
      if (reservationEnabled != null) {
        request.fields['reservationEnabled'] = reservationEnabled.toString();
      }
      if (eventType != null) request.fields['eventType'] = eventType.value;
      if (locationType != null) request.fields['locationType'] = locationType.value;
      if (visibility != null) request.fields['visibility'] = visibility.value;
      if (status != null) request.fields['status'] = status.value;

      if (coverFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'cover',
          coverFile.path,
          contentType: _mediaTypeFromPath(coverFile.path),
        ));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return Event.fromJson(data['event'] as Map<String, dynamic>);
  }

  static Future<void> deleteEvent({
    required String token,
    required String eventId,
  }) async {
    http.Response response;
    try {
      response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/events/$eventId'),
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

  static Future<List<Event>> getMyEvents({required String token}) async {
    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/events/my'),
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
    return (data['events'] as List<dynamic>)
        .map((e) => Event.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static MediaType _mediaTypeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'mp4' => MediaType('video', 'mp4'),
      'mov' => MediaType('video', 'quicktime'),
      'avi' => MediaType('video', 'x-msvideo'),
      _ => MediaType('image', 'jpeg'),
    };
  }
}
