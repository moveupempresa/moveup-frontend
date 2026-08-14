import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../models/profile.dart';
import 'auth_service.dart';

class ProfileService {
  static Future<Profile> updateProfile({
    required String token,
    String? displayName,
    String? artisticName,
    String? bio,
    String? city,
    String? country,
    String? websiteUrl,
    String? cvUrl,
    int? experience,
    Map<String, String>? socialLinks,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (artisticName != null) body['artisticName'] = artisticName;
    if (bio != null) body['bio'] = bio;
    if (city != null) body['city'] = city;
    if (country != null) body['country'] = country;
    if (websiteUrl != null) body['websiteUrl'] = websiteUrl;
    if (cvUrl != null) body['cvUrl'] = cvUrl;
    if (experience != null) body['experience'] = experience;
    if (socialLinks != null) body['socialLinks'] = socialLinks;

    return _profileRequest(
      method: 'PATCH',
      endpoint: 'profile/me',
      token: token,
      body: body,
    );
  }

  static Future<(Profile, String, bool, int)> getUserProfile({
    required String token,
    required String userId,
  }) async {
    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/profile/$userId'),
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
    final profile = Profile.fromJson(data['profile'] as Map<String, dynamic>);
    final username = data['username'] as String;
    final isFollowing = data['isFollowing'] as bool? ?? false;
    final followersCount = data['followersCount'] as int? ?? 0;
    return (profile, username, isFollowing, followersCount);
  }

  static Future<Profile> addGalleryAlbum({
    required String token,
    required List<File> mediaFiles,
  }) async {
    http.Response response;
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/profile/me/gallery'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      for (final file in mediaFiles) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            file.path,
            contentType: _mediaTypeFromPath(file.path),
          ),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }
    return _parseProfile(response);
  }

  static Future<Profile> removeGalleryAlbum({
    required String token,
    required String id,
  }) async {
    http.Response response;
    try {
      final request = http.Request(
        'DELETE',
        Uri.parse('${ApiConfig.baseUrl}/profile/me/gallery'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';
      request.body = jsonEncode({'id': id});
      final streamed = await request.send().timeout(
        const Duration(seconds: 10),
      );
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }
    return _parseProfile(response);
  }

  static Future<Profile> uploadProfileImage({
    required String token,
    required File imageFile,
  }) => _uploadImage(
    token: token,
    imageFile: imageFile,
    endpoint: 'profile/me/profile-image',
  );

  static Future<Profile> uploadCv({
    required String token,
    required File file,
  }) async {
    http.Response response;
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/profile/me/cv'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'cv',
          file.path,
          contentType: _cvMediaTypeFromPath(file.path),
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }
    return _parseProfile(response);
  }

  static Future<Profile> _uploadImage({
    required String token,
    required File imageFile,
    required String endpoint,
  }) async {
    http.Response response;
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: _mediaTypeFromPath(imageFile.path),
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }
    return _parseProfile(response);
  }

  static Future<Profile> _profileRequest({
    required String method,
    required String endpoint,
    required String token,
    Map<String, dynamic>? body,
  }) async {
    http.Response response;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      if (method == 'PATCH') {
        response = await http
            .patch(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 10));
      } else {
        response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 10));
      }
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor');
    }
    return _parseProfile(response);
  }

  static MediaType _cvMediaTypeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => MediaType('application', 'pdf'),
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      _ => MediaType('image', 'jpeg'),
    };
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

  static Profile _parseProfile(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(data['message'] as String? ?? 'Ocurrió un error');
    }
    return Profile.fromJson(data['profile'] as Map<String, dynamic>);
  }
}
