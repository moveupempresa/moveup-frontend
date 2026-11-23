import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'device_token_service.dart';

// Must be a top-level/static function - the OS runs it in a separate
// isolate when a push arrives while the app is backgrounded or killed.
// There's nothing to do here: Android and iOS already show the system
// notification themselves from the message's "notification" payload.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Requests notification permission, registers this device's FCM token with
/// the backend, and keeps it updated if Firebase rotates it.
///
/// Deliberately keeps using the classic token API (getToken/onTokenRefresh)
/// instead of the newer register()/onRegistered flow this package version
/// nudges toward - that flow hands back a Firebase Installation ID rather
/// than a plain FCM token, and the backend (firebase-admin's
/// sendEachForMulticast) is built around classic tokens.
class PushNotificationService {
  static String? _lastRegisteredToken;

  static Future<void> registerDevice(String authToken) async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // ignore: deprecated_member_use
    final deviceToken = await messaging.getToken();
    if (deviceToken == null) return;

    final platform = Platform.isIOS ? 'ios' : 'android';
    _lastRegisteredToken = deviceToken;
    try {
      await DeviceTokenService.register(
        token: authToken,
        deviceToken: deviceToken,
        platform: platform,
      );
    } catch (_) {
      // Not fatal - this device just won't get push until the next
      // successful registration (e.g. the next time the app opens).
    }

    // ignore: deprecated_member_use
    messaging.onTokenRefresh.listen((newToken) {
      _lastRegisteredToken = newToken;
      DeviceTokenService.register(
        token: authToken,
        deviceToken: newToken,
        platform: platform,
      ).catchError((_) {});
    });
  }

  static Future<void> unregisterDevice(String authToken) async {
    final deviceToken =
        _lastRegisteredToken ??
        // ignore: deprecated_member_use
        await FirebaseMessaging.instance.getToken();
    if (deviceToken == null) return;
    try {
      await DeviceTokenService.unregister(
        token: authToken,
        deviceToken: deviceToken,
      );
    } catch (_) {
      // Logging out locally still succeeds even if this cleanup fails.
    }
  }
}
