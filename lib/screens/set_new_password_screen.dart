import 'package:flutter/material.dart' hide Text;

import '../services/auth_service.dart';
import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';
import 'signin_screen.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await widget.authService.updatePassword(
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SignInScreen(
            authService: widget.authService,
            initialMessage: 'Password updated. Please sign in.',
          ),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _visibilityToggle(bool obscured, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: primaryText(context),
      ),
      onPressed: onPressed,
    );
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 16),
                    authBackButton(context),
                    SizedBox(height: 32),
                    Text(
                      'Setup new password',
                      style: TextStyle(
                        color: primaryText(context),
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose a new password for your account.',
                      style: TextStyle(
                        color: mutedText(context),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 32),
                    Text('New Password', style: labelStyle),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: [AutofillHints.newPassword],
                      decoration: authFieldDecoration(
                        context,
                        hint: 'Enter a new password',
                        icon: Icons.lock_outline,
                        suffixIcon: _visibilityToggle(
                          _obscurePassword,
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('Please enter a new password');
                        }
                        if (value.length < 8) {
                          return tr('Password must be at least 8 characters');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    Text('Confirm Password', style: labelStyle),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      autofillHints: [AutofillHints.newPassword],
                      decoration: authFieldDecoration(
                        context,
                        hint: 'Re-enter your new password',
                        icon: Icons.lock_outline,
                        suffixIcon: _visibilityToggle(
                          _obscureConfirm,
                          () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return tr('Passwords do not match');
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _updatePassword(),
                    ),
                    Spacer(),
                    SizedBox(height: 32),
                    FilledButton(
                      onPressed: _isLoading ? null : _updatePassword,
                      style: FilledButton.styleFrom(
                        backgroundColor: authAccentColor,
                        foregroundColor: buttonTextColor(context),
                        disabledBackgroundColor: authAccentColor.withValues(
                          alpha: 0.6,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryText(context),
                              ),
                            )
                          : Text('Update Password'),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
