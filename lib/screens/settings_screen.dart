import 'package:flutter/material.dart' hide Text;
import 'package:package_info_plus/package_info_plus.dart';

import '../services/error_notifier.dart';
import '../services/language.dart';
import '../services/settings_store.dart';
import '../services/theme_controller.dart';
import '../services/auth_service.dart';
import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';
import 'change_password_screen.dart';
import 'customer_service_screen.dart';
import 'about_sheet.dart';
import 'legal_screens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _showPhone = false;
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final results = await Future.wait([
      SettingsStore.pushNotifications,
      SettingsStore.emailNotifications,
      SettingsStore.showPhone,
      PackageInfo.fromPlatform(),
    ]);
    if (!mounted) return;
    setState(() {
      _pushNotifications = results[0] as bool;
      _emailNotifications = results[1] as bool;
      _showPhone = results[2] as bool;
      _version = (results[3] as PackageInfo).version;
    });
  }

  Future<void> _setPush(bool value) async {
    setState(() => _pushNotifications = value);
    await SettingsStore.write(SettingsStore.pushNotificationsKey, value);
    ErrorNotifier.setPushEnabled(value);
  }

  Future<void> _setEmail(bool value) async {
    setState(() => _emailNotifications = value);
    await SettingsStore.write(SettingsStore.emailNotificationsKey, value);
  }

  Future<void> _setShowPhone(bool value) async {
    setState(() => _showPhone = value);
    await SettingsStore.write(SettingsStore.showPhoneKey, value);
  }

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardBackground(dialogContext),
        title: Text(
          'SeatNix',
          style: TextStyle(color: primaryText(dialogContext)),
        ),
        content: Text(
          '${tr('Version')} $_version\n${tr('Plan. Book. Ride.')}',
          style: TextStyle(color: mutedText(dialogContext)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
  }

  Future<void> _chooseTheme() async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(tr('Choose theme')),
        children: [
          for (final mode in ThemeMode.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(mode),
              child: Row(
                children: [
                  Icon(
                    mode == themeController.value
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: accentColor(context),
                  ),
                  const SizedBox(width: 12),
                  Text(_themeLabel(mode)),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || selected == themeController.value) return;
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    await themeController.setThemeMode(selected);
  }

  Future<void> _chooseLanguage() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(tr('Choose language')),
        children: [
          for (final option in const [
            (languageEnglish, 'English'),
            (languageUrdu, 'اردو'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(option.$1),
              child: Row(
                children: [
                  Icon(
                    option.$1 == languageController.value
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: accentColor(context),
                  ),
                  const SizedBox(width: 12),
                  Text(option.$2),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || selected == languageController.value) return;
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    await languageController.setLanguage(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground(context),
      appBar: AppBar(
        backgroundColor: screenBackground(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            directionalBackIcon(context),
            textDirection: TextDirection.ltr,
            color: primaryText(context),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: primaryText(context),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          const _SectionTitle('Notifications'),
          _SwitchRow(
            title: 'Push notifications',
            subtitle: 'Trip updates and seat alerts',
            value: _pushNotifications,
            onChanged: _setPush,
          ),
          _SwitchRow(
            title: 'Email notifications',
            subtitle: 'Booking receipts and news',
            value: _emailNotifications,
            onChanged: _setEmail,
          ),
          const _SectionTitle('Privacy'),
          _SwitchRow(
            title: 'Show phone number',
            subtitle: 'Let drivers see your phone number',
            value: _showPhone,
            onChanged: _setShowPhone,
          ),
          _NavRow(
            title: 'Change password',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ChangePasswordScreen(authService: widget.authService),
              ),
            ),
          ),
          const _SectionTitle('Appearance'),
          _NavRow(
            title: 'Theme',
            trailingText: _themeLabel(themeController.value),
            onTap: _chooseTheme,
          ),
          const _SectionTitle('Support'),
          _NavRow(
            title: 'Customer service',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerServiceScreen()),
            ),
          ),
          const _SectionTitle('General'),
          _NavRow(
            title: 'Language',
            trailingText: isUrdu ? 'اردو' : 'English',
            onTap: _chooseLanguage,
          ),
          _NavRow(
            title: 'Privacy policy',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LegalDocumentScreen(
                  titleKey: 'Privacy policy',
                  sections: privacyPolicySections,
                ),
              ),
            ),
          ),
          _NavRow(
            title: 'Terms of service',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LegalDocumentScreen(
                  titleKey: 'Terms of service',
                  sections: termsSections,
                ),
              ),
            ),
          ),
          const _SectionTitle('About'),
          _NavRow(
            title: 'About SeatNix',
            trailingText: 'Team & story',
            onTap: () => showAboutSheet(context, version: _version),
          ),
          _NavRow(
            title: 'App version',
            trailingText: _version,
            onTap: _showAbout,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        tr(title).toUpperCase(),
        style: TextStyle(
          color: accentColor(context),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.white,
          activeTrackColor: accentColor(context),
          title: Text(
            title,
            style: TextStyle(
              color: primaryText(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: mutedText(context), fontSize: 13),
          ),
          value: value,
          onChanged: onChanged,
        ),
        Divider(height: 1, color: dividerColor(context)),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.title, this.trailingText, this.onTap});

  final String title;
  final String? trailingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: primaryText(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailingText != null) ...[
                  Text(
                    trailingText!,
                    style: TextStyle(color: mutedText(context), fontSize: 15),
                  ),
                  const SizedBox(width: 4),
                ],
                if (onTap != null)
                  Icon(
                    directionalChevronIcon(context),
                    textDirection: TextDirection.ltr,
                    color: mutedText(context),
                  ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: dividerColor(context)),
      ],
    );
  }
}
