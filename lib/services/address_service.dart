import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AddressSuggestion {
  final String displayName;

  const AddressSuggestion({required this.displayName});
}

class AddressService {
  static Future<List<AddressSuggestion>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': trimmed,
      'format': 'json',
      'addressdetails': '0',
      'limit': '5',
      'countrycodes': 'es',
    });

    http.Response response;
    try {
      response = await http
          .get(uri, headers: {'User-Agent': 'MoveUpApp/1.0'})
          .timeout(const Duration(seconds: 8));
    } on SocketException {
      return [];
    } catch (_) {
      return [];
    }

    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => AddressSuggestion(displayName: item['display_name'] as String))
        .toList();
  }
}
