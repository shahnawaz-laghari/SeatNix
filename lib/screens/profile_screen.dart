import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/settings_store.dart';
import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';
import 'edit_profile_screen.dart';
import 'payment_details_screen.dart';
import 'travel_history_screen.dart';
import 'settings_screen.dart';
import 'signin_screen.dart';

const _editColor = Color(0xFF0B57A4);
const _logoutColor = Color(0xFFE23B3B);

const _headerHeight = 200.0;
const _panelTop = 150.0;
const _avatarSize = 128.0;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _refreshAccount();
  }

  Future<void> _refreshAccount() async {
    final showPhone = await SettingsStore.showPhone;
    if (mounted) setState(() => _showPhone = showPhone);
    try {
      await widget.authService.currentUser();
      await widget.authService.currentAvatar();
    } on AuthException {
      // Keep the profile screen available with placeholders when offline.
    }
    if (mounted) setState(() {});
  }

  Future<void> _logout(BuildContext context) async {
    await widget.authService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SignInScreen(authService: widget.authService),
      ),
      (route) => false,
    );
  }

  bool _uploadingAvatar = false;

  bool _showPhone = false;

  bool get _supportsCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _showPhotoOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_supportsCamera)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  _pickAndUpload(context, ImageSource.camera);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                _pickAndUpload(context, ImageSource.gallery);
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, ImageSource source) async {
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('Could not open the picker: {error}', {'error': '$e'}),
          ),
        ),
      );
      return;
    }
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      await widget.authService.updateAvatar(
        bytes: bytes,
        contentType: picked.mimeType ?? 'image/jpeg',
      );
      await widget.authService.currentAvatar();
      if (mounted) setState(() {});
    } on AuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: const Color(0xFFEEF2F1),
      child: Icon(Icons.person, size: 64, color: mutedText(context)),
    );
  }

  Widget _avatarImage(Uint8List? bytes) {
    if (bytes == null) return _avatarPlaceholder();
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _avatarPlaceholder(),
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(authService: widget.authService),
      ),
    );
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = AppwriteAuthService.cachedUser;
    final name = user?.name ?? '-';
    final avatarBytes = AppwriteAuthService.cachedAvatar;
    final email = user?.email ?? '-';
    final phone = _showPhone ? (user?.phoneNumber ?? '-') : 'Hidden';

    return Scaffold(
      backgroundColor: screenBackground(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(height: _headerHeight, color: accentColor(context)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  textDirection: Directionality.of(context),
                  children: [
                    IconButton(
                      icon: Icon(
                        directionalBackIcon(context),
                        textDirection: TextDirection.ltr,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SettingsScreen(authService: widget.authService),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: _panelTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: cardBackground(context),
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    _avatarSize / 2 + 24,
                    24,
                    24,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _ProfileField(label: 'Name', value: name),
                              _ProfileField(label: 'Email', value: email),
                              _ProfileField(label: 'Phone No', value: phone),
                              _ProfileField(
                                label: 'Password',
                                value: '\u2022' * 10,
                                icon: Icons.lock_outline,
                              ),
                              const SizedBox(height: 8),
                              _MenuRow(
                                title: 'Payment Details',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PaymentDetailsScreen(),
                                  ),
                                ),
                              ),
                              Divider(height: 1, color: dividerColor(context)),
                              _MenuRow(
                                title: 'Travel history',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TravelHistoryScreen(),
                                  ),
                                ),
                              ),
                              Divider(height: 1, color: dividerColor(context)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _openEditProfile(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: _editColor,
                                foregroundColor: buttonTextColor(context),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.edit_outlined, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _logout(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _logoutColor,
                                side: const BorderSide(
                                  color: _logoutColor,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Log out',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.logout, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: _panelTop - _avatarSize / 2,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _uploadingAvatar
                    ? null
                    : () => _showPhotoOptions(context),
                child: Container(
                  width: _avatarSize,
                  height: _avatarSize,
                  decoration: BoxDecoration(
                    color: isDarkMode(context)
                        ? const Color(0xFF262C2F)
                        : const Color(0xFFEEF2F1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: cardBackground(context),
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _avatarImage(avatarBytes),
                        if (_uploadingAvatar)
                          Container(
                            color: Colors.black26,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InputDecorator(
        decoration: InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 14, color: mutedText(context)),
              ],
            ],
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: dividerColor(context)),
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: primaryText(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: mutedText(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              directionalChevronIcon(context),
              textDirection: TextDirection.ltr,
              color: mutedText(context),
            ),
          ],
        ),
      ),
    );
  }
}
