import 'package:shared_preferences/shared_preferences.dart';

class RecentEmails {
  static const _key = 'recent_emails';
  static const _maxItems = 5;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> add(String email) async {
    final normalized = email.trim();
    final prefs = await SharedPreferences.getInstance();
    final emails = prefs.getStringList(_key) ?? [];
    emails.removeWhere((e) => e.toLowerCase() == normalized.toLowerCase());
    emails.insert(0, normalized);
    await prefs.setStringList(_key, emails.take(_maxItems).toList());
  }
}
