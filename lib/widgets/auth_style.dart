import 'package:flutter/material.dart';

import '../services/error_notifier.dart';
import '../services/language.dart';

bool isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color screenBackground(BuildContext context) =>
    isDarkMode(context) ? const Color(0xFF121416) : Colors.white;

Color cardBackground(BuildContext context) =>
    isDarkMode(context) ? const Color(0xFF1E2326) : Colors.white;

Color primaryText(BuildContext context) =>
    isDarkMode(context) ? const Color(0xFFF2F5F4) : authTextColor;

Color mutedText(BuildContext context) =>
    isDarkMode(context) ? const Color(0xFF9AA3A1) : authMutedColor;

Color buttonTextColor(BuildContext context) =>
    isDarkMode(context) ? const Color(0xFF14181A) : Colors.white;

Color dividerColor(BuildContext context) =>
    isDarkMode(context) ? const Color(0xFF3A4245) : const Color(0xFFD5DAD9);

/// Subtle card edge: black in light mode, orange in dark mode.
BorderSide appCardBorder(BuildContext context) => BorderSide(
  color: isDarkMode(context)
      ? accentColor(context).withValues(alpha: 0.45)
      : Colors.black.withValues(alpha: 0.22),
  width: isDarkMode(context) ? 1.2 : 1,
);

/// Soft card shadow: black in light mode, orange in dark mode.
List<BoxShadow> appCardShadow(BuildContext context) => [
  BoxShadow(
    color: isDarkMode(context)
        ? accentColor(context).withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08),
    blurRadius: 6,
    spreadRadius: 0,
    offset: const Offset(0, 2),
  ),
];

bool isRtlLayout(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl;

IconData directionalBackIcon(BuildContext context, {bool iosStyle = false}) {
  if (iosStyle) {
    return isRtlLayout(context)
        ? Icons.arrow_forward_ios
        : Icons.arrow_back_ios_new;
  }
  return isRtlLayout(context) ? Icons.arrow_forward : Icons.arrow_back;
}

IconData directionalChevronIcon(BuildContext context) =>
    isRtlLayout(context) ? Icons.chevron_left : Icons.chevron_right;

const authTextColor = Color(0xFF0E2E2B);
const authMutedColor = Color(0xFF8A9391);

/// Theme-aware orange: lighter in light mode, deeper in dark mode.
Color accentColor(BuildContext context) =>
    isDarkMode(context) ? const Color(0xFFD48300) : const Color(0xFFF5A00D);

InputDecoration authFieldDecoration(
  BuildContext context, {
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  final muted = mutedText(context);
  final text = primaryText(context);
  final border = OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: muted),
  );
  final errorColor = Theme.of(context).colorScheme.error;
  return InputDecoration(
    hintText: tr(hint),
    hintStyle: TextStyle(color: muted),
    prefixIcon: Icon(icon, color: text),
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: text, width: 1.5),
    ),
    errorBorder: border.copyWith(borderSide: BorderSide(color: errorColor)),
    focusedErrorBorder: border.copyWith(
      borderSide: BorderSide(color: errorColor, width: 1.5),
    ),
  );
}

Widget authBackButton(BuildContext context) {
  final dark = isDarkMode(context);
  return Align(
    alignment: AlignmentDirectional.centerStart,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF262C2F) : const Color(0xFFEEF2F1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          directionalBackIcon(context, iosStyle: true),
          textDirection: TextDirection.ltr,
          size: 18,
          color: primaryText(context),
        ),
      ),
    ),
  );
}

void showAuthSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2E7D32),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr(message),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
}

void showAuthError(BuildContext context, String message) {
  final translated = tr(message);
  ErrorNotifier.showAuthError(translated);
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDarkMode(context)
            ? const Color(0xFF8C1D18)
            : const Color(0xFFB3261E),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                translated,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
}
