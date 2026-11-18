import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows on-device notifications for authentication errors on mobile.
/// On web there is no device notification area, so the in-app error banner
/// shown by [showAuthError] is the visible feedback.
class ErrorNotifier {
  ErrorNotifier._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  static Future<void> showAuthError(String message) async {
    if (kIsWeb) return;
    try {
      await initialize();
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'SeatNix sign-in',
        body: message,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'auth_errors',
            'Sign-in alerts',
            channelDescription: 'Alerts about incorrect sign-in details.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // In-app feedback is always shown even if the device notification fails.
    }
  }
}
