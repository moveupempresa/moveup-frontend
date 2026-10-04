import 'package:shared_preferences/shared_preferences.dart';

/// Persists "where the user currently is" (active bottom-nav tab, and the
/// event detail screen if one is open) so the app can return there after
/// being killed and relaunched by the OS while backgrounded - Flutter's own
/// state restoration doesn't fit this app's navigation (screens are passed
/// full objects and a token via constructors, not via serializable
/// arguments resolvable before the session is restored), so this is a
/// lighter, purpose-built equivalent covering the main flows.
class AppLocationService {
  static const _tabKey = 'last_tab_index';
  static const _eventKey = 'last_event_id';

  static Future<void> saveTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tabKey, index);
  }

  static Future<int> loadTab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tabKey) ?? 0;
  }

  static Future<void> saveOpenEvent(String? eventId) async {
    final prefs = await SharedPreferences.getInstance();
    if (eventId == null) {
      await prefs.remove(_eventKey);
    } else {
      await prefs.setString(_eventKey, eventId);
    }
  }

  static Future<String?> loadOpenEvent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_eventKey);
  }
}
