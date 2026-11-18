import 'package:flutter/material.dart' hide Text;

import '../services/auth_service.dart';
import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';
import 'email_verification_code_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _localError() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return 'Please enter a username';
    if (username.length < 3) return 'Username must be at least 3 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Use only letters, numbers and underscores';
    }
    final email = _emailController.text.trim();
    if (email.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email';
    }
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return 'Please enter your phone number';
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)) {
      return 'Please enter a valid phone number';
    }
    if (_passwordController.text.isEmpty) return 'Please enter a password';
    if (_passwordController.text.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (_confirmController.text != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      final localError = _localError();
      if (localError != null) showAuthError(context, localError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await widget.authService.signUp(
        username: _usernameController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (result.requiresCode) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EmailVerificationCodeScreen(
              authService: widget.authService,
              userId: result.userId!,
            ),
          ),
        );
        return;
      }
      Navigator.of(context).pop(result);
    } on AuthException catch (e) {
      if (!mounted) return;
      showAuthError(context, e.message);
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
    final helperStyle = TextStyle(color: mutedText(context), fontSize: 12);

    return Scaffold(
      backgroundColor: screenBackground(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 48),
                Text(
                  'Create an account',
                  style: TextStyle(
                    color: primaryText(context),
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  children: [
                    Text(
                      'Enter your account details below or ',
                      style: TextStyle(
                        color: primaryText(context),
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'sign in',
                              style: TextStyle(
                                color: primaryText(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Container(height: 1.5, color: primaryText(context)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 28),
                Text('Username', style: labelStyle),
                SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: [AutofillHints.username],
                  decoration: authFieldDecoration(
                    context,
                    hint: 'Choose a username',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return tr('Please enter a username');
                    if (v.length < 3) {
                      return tr('Username must be at least 3 characters');
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                      return tr('Use only letters, numbers and underscores');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Text('Email', style: labelStyle),
                SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: [AutofillHints.email],
                  decoration: authFieldDecoration(
                    context,
                    hint: 'you@example.com',
                    icon: Icons.mail_outline,
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return tr('Please enter your email');
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                      return tr('Please enter a valid email');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Text('Phone No', style: labelStyle),
                SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: [AutofillHints.telephoneNumber],
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
                ),
                SizedBox(height: 20),
                Text('Password', style: labelStyle),
                SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: [AutofillHints.newPassword],
                  decoration: authFieldDecoration(
                    context,
                    hint: 'Create a password',
                    icon: Icons.lock_outline,
                    suffixIcon: _visibilityToggle(
                      _obscurePassword,
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('Please enter a password');
                    }
                    if (value.length < 8) {
                      return tr('Password must be at least 8 characters');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 6),
                Text('At least 8 characters', style: helperStyle),
                SizedBox(height: 14),
                Text('Confirm password', style: labelStyle),
                SizedBox(height: 8),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: authFieldDecoration(
                    context,
                    hint: 'Re-enter your password',
                    icon: Icons.lock_outline,
                    suffixIcon: _visibilityToggle(
                      _obscureConfirm,
                      () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return tr('Passwords do not match');
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor(context),
                    foregroundColor: buttonTextColor(context),
                    disabledBackgroundColor: accentColor(context)
                        .withValues(alpha: 0.6),
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
                      : Text('Sign Up'),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
