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

    final results = await _search(trimmed);
    if (results.isNotEmpty || !trimmed.contains(',')) return results;

    // Nominatim's free-text matcher often fails when a venue/business name
    // is prefixed onto the address (e.g. "Academia Pineda, Carrer Aragó 10,
    // Barcelona"), even though the address portion alone resolves fine. Fall
    // back to searching just the part after the first comma.
    final addressOnly = trimmed.substring(trimmed.indexOf(',') + 1).trim();
    if (addressOnly.length < 3) return results;
    return _search(addressOnly);
  }

  static Future<List<AddressSuggestion>> _search(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'addressdetails': '0',
      'limit': '5',
      'countrycodes': 'es',
    });

    http.Response response;
    try {
      response = await http
          .get(uri, headers: {'User-Agent': 'MoveUpApp/1.0 (contact@moveupapp.com)'})
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
