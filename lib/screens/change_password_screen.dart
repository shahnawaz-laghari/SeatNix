import 'package:flutter/material.dart' hide Text;

import '../services/auth_service.dart';
import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.authService.changePassword(
        oldPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAuthSuccess(context, 'Password changed successfully.');
    } on AuthException catch (e) {
      if (!mounted) return;
      showAuthError(context, e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    TextInputAction action = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            color: primaryText(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          textInputAction: action,
          autofillHints: const [AutofillHints.password],
          decoration: authFieldDecoration(
            context,
            hint: hint,
            icon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: primaryText(context),
              ),
              onPressed: onToggle,
            ),
          ),
          validator: validator,
        ),
        const SizedBox(height: 18),
      ],
    );
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
          'Change password',
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
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter your current password and choose a new one.',
                  style: TextStyle(color: mutedText(context), fontSize: 14),
                ),
                const SizedBox(height: 24),
                _field(
                  controller: _currentController,
                  label: 'Current password',
                  hint: 'Enter current password',
                  obscure: _obscureCurrent,
                  onToggle: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (value) => value?.isNotEmpty == true
                      ? null
                      : tr('Please enter your current password'),
                ),
                _field(
                  controller: _newController,
                  label: 'New password',
                  hint: 'At least 8 characters',
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return tr('Please enter a new password');
                    }
                    if (value!.length < 8) {
                      return tr('Password must be at least 8 characters');
                    }
                    return null;
                  },
                ),
                _field(
                  controller: _confirmController,
                  label: 'Confirm new password',
                  hint: 'Re-enter new password',
                  obscure: true,
                  onToggle: () {},
                  action: TextInputAction.done,
                  validator: (value) => value == _newController.text
                      ? null
                      : tr('Passwords do not match'),
                ),
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
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
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Update password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
