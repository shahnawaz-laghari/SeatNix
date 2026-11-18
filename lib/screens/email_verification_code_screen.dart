import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';
import 'signin_screen.dart';

class EmailVerificationCodeScreen extends StatefulWidget {
  const EmailVerificationCodeScreen({
    super.key,
    required this.authService,
    required this.userId,
  });

  final AuthService authService;
  final String userId;

  @override
  State<EmailVerificationCodeScreen> createState() =>
      _EmailVerificationCodeScreenState();
}

class _EmailVerificationCodeScreenState
    extends State<EmailVerificationCodeScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Please enter the 6-digit code'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.authService.verifyEmailCode(
        userId: widget.userId,
        code: code,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SignInScreen(
            authService: widget.authService,
            initialMessage: 'Email verified. You can now sign in.',
          ),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground(context),
      appBar: AppBar(
        backgroundColor: screenBackground(context),
        foregroundColor: primaryText(context),
        elevation: 0,
        title: Text('Verify your email'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the 6-digit code we sent to your email address.',
                style: TextStyle(
                  color: mutedText(context),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: TextStyle(
                  color: primaryText(context),
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w700,
                ),
                decoration: authFieldDecoration(
                  context,
                  hint: '000000',
                  icon: Icons.mark_email_read_outlined,
                ).copyWith(counterText: ''),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isLoading ? null : _verify,
                style: FilledButton.styleFrom(
                  backgroundColor: authAccentColor,
                  foregroundColor: buttonTextColor(context),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Verify email'),
              ),
              const SizedBox(height: 16),
              Text(
                'If the code expires, sign in to request another verification code.',
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedText(context), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
