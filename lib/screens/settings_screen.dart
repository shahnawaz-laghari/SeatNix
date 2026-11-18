import 'package:flutter/material.dart' hide Text;

import '../services/language.dart';
import '../services/theme_controller.dart';
import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';
import 'customer_service_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _showPhone = false;

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            tr('{feature} is coming soon.', {'feature': tr(feature)}),
          ),
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
                    color: authAccentColor,
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
                    color: authAccentColor,
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
            onChanged: (value) => setState(() => _pushNotifications = value),
          ),
          _SwitchRow(
            title: 'Email notifications',
            subtitle: 'Booking receipts and news',
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
          ),
          const _SectionTitle('Privacy'),
          _SwitchRow(
            title: 'Show phone number',
            subtitle: 'Let drivers see your phone number',
            value: _showPhone,
            onChanged: (value) => setState(() => _showPhone = value),
          ),
          _NavRow(
            title: 'Change password',
            onTap: () => _comingSoon('Change password'),
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
            onTap: () => _comingSoon('Privacy policy'),
          ),
          _NavRow(
            title: 'Terms of service',
            onTap: () => _comingSoon('Terms of service'),
          ),
          const _SectionTitle('About'),
          const _NavRow(title: 'App version', trailingText: '1.0.0'),
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
        style: const TextStyle(
          color: authAccentColor,
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
          activeTrackColor: authAccentColor,
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
