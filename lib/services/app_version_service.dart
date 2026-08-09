import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../config/api_config.dart';

class AppVersionService {
  static Future<bool> isUpdateAvailable() async {
    final info = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(info.buildNumber) ?? 0;

    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/app/version'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode >= 400) return false;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final latestBuild = data['latestBuildNumber'] as int? ?? 0;
    return latestBuild > currentBuild;
  }
}
