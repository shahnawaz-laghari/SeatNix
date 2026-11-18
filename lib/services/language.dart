import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/urdu.dart';

const languageEnglish = 'en';
const languageUrdu = 'ur';

class LanguageController extends ValueNotifier<String> {
  LanguageController() : super(languageEnglish);

  static const _key = 'app_language';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getString(_key) ?? languageEnglish;
  }

  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    value = code;
  }
}

final languageController = LanguageController();

bool get isUrdu => languageController.value == languageUrdu;

/// Returns the translated text for [english] when Urdu is selected.
/// Placeholders such as {name} in the text are replaced with [args].
/// Text without a translation is returned unchanged.
String tr(String english, [Map<String, String> args = const {}]) {
  var text = isUrdu ? (urduTranslations[english] ?? english) : english;
  args.forEach((key, value) {
    text = text.replaceAll('{$key}', value);
  });
  return text;
}
