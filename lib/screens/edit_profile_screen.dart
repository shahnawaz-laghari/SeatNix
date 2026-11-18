import 'package:flutter/material.dart' hide Text;

import '../widgets/localized_text.dart';

import '../services/auth_service.dart';
import '../widgets/auth_style.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final String _email;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = AppwriteAuthService.cachedUser;
    _usernameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _email = user?.email ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.authService.updateProfile(
        username: _usernameController.text,
        phoneNumber: _phoneController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: primaryText(context),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

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
          'Edit Profile',
          style: TextStyle(
            color: primaryText(context),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Name', style: labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: authFieldDecoration(
                    context,
                    hint: 'Your name',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return tr('Please enter your name');
                    if (v.length < 3) {
                      return tr('Name must be at least 3 characters');
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                      return tr('Use only letters, numbers and underscores');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text('Email', style: labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _email,
                  readOnly: true,
                  decoration: authFieldDecoration(
                    context,
                    hint: 'you@example.com',
                    icon: Icons.mail_outline,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Email cannot be changed here.',
                  style: TextStyle(color: mutedText(context), fontSize: 12),
                ),
                const SizedBox(height: 20),
                Text('Phone No', style: labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: authFieldDecoration(
                    context,
                    hint: '+92 300 1234567',
                    icon: Icons.phone_outlined,
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return tr('Please enter your phone number');
                    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(v)) {
                      return tr('Please enter a valid phone number');
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: authAccentColor,
                    foregroundColor: buttonTextColor(context),
                    disabledBackgroundColor: authAccentColor.withValues(
                      alpha: 0.6,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryText(context),
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
