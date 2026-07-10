class ApiConfig {
  // Your computer's LAN IP — phone and computer must be on the same Wi-Fi.
  static const String serverUrl = 'http://13.60.213.176:3000';
  static const String baseUrl = '$serverUrl/api';

  static String mediaUrl(String relativePath) => '$serverUrl$relativePath';
}
