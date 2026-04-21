import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static StreamSubscription<String>? _tokenSub;
  static StreamSubscription<RemoteMessage>? _messageSub;
  static final _foregroundMessages = StreamController<RemoteMessage>.broadcast();
  static String? _lastToken;

  static String? get lastToken => _lastToken;
  static Stream<RemoteMessage> get foregroundMessages => _foregroundMessages.stream;

  static Future<void> initialize({
    GlobalKey<NavigatorState>? navigatorKey,
    GlobalKey<ScaffoldMessengerState>? messengerKey,
  }) async {
    // APNS-backed FCM flows are only expected on mobile Apple targets.
    // On macOS/desktop debug this can throw noisy platform errors.
    final isSupportedPushTarget = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!isSupportedPushTarget) {
      if (kDebugMode) {
        debugPrint('FCM native token flow skipped on this platform.');
      }
      return;
    }

    final messaging = FirebaseMessaging.instance;
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (kDebugMode) {
        debugPrint('FCM permission: ${settings.authorizationStatus}');
      }
    } catch (error) {
      // Desktop targets can reject notification permission at runtime.
      // Keep app startup alive so user flows are testable.
      if (kDebugMode) {
        debugPrint('FCM permission request failed: $error');
      }
    }

    try {
      _lastToken = await messaging.getToken();
      _tokenSub?.cancel();
      _tokenSub = messaging.onTokenRefresh.listen((token) {
        _lastToken = token;
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('FCM token setup failed: $error');
      }
    }

    _messageSub?.cancel();
    _messageSub = FirebaseMessaging.onMessage.listen((message) {
      _foregroundMessages.add(message);
      final messenger = messengerKey?.currentState;
      if (messenger != null) {
        final title = message.notification?.title ?? 'New notification';
        final body = message.notification?.body ?? '';
        messenger.showSnackBar(
          SnackBar(content: Text(body.isEmpty ? title : '$title: $body')),
        );
      }
    });

    try {
      await messaging.subscribeToTopic('all-users');
    } catch (error) {
      if (kDebugMode) {
        debugPrint('FCM topic subscribe failed: $error');
      }
    }
  }

  static Future<void> dispose() async {
    await _tokenSub?.cancel();
    await _messageSub?.cancel();
    await _foregroundMessages.close();
    _tokenSub = null;
    _messageSub = null;
  }
}
