import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's Settings choices on this device.
class SettingsStore {
  SettingsStore._();

  static const pushNotificationsKey = 'settings_push_notifications';
  static const emailNotificationsKey = 'settings_email_notifications';
  static const showPhoneKey = 'settings_show_phone';

  static Future<bool> read(String key, {required bool fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? fallback;
  }

  static Future<void> write(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool> get pushNotifications =>
      read(pushNotificationsKey, fallback: true);

  static Future<bool> get emailNotifications =>
      read(emailNotificationsKey, fallback: false);

  static Future<bool> get showPhone => read(showPhoneKey, fallback: false);
}
