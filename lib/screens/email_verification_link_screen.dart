import 'package:flutter/material.dart' hide Text;

import '../services/auth_service.dart';
import '../utils/clear_verification_url_stub.dart'
    if (dart.library.js_interop) '../utils/clear_verification_url_web.dart'
    as url_cleaner;
import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';
import 'signin_screen.dart';

class EmailVerificationLinkScreen extends StatefulWidget {
  const EmailVerificationLinkScreen({
    super.key,
    required this.authService,
    required this.userId,
    required this.secret,
  });

  final AuthService authService;
  final String userId;
  final String secret;

  @override
  State<EmailVerificationLinkScreen> createState() =>
      _EmailVerificationLinkScreenState();
}

class _EmailVerificationLinkScreenState
    extends State<EmailVerificationLinkScreen> {
  @override
  void initState() {
    super.initState();
    url_cleaner.clearVerificationQueryFromUrl();
    _verify();
  }

  Future<void> _verify() async {
    String message;
    try {
      await widget.authService.verifyEmailLink(
        userId: widget.userId,
        secret: widget.secret,
      );
      message = 'Email verified. You can now sign in.';
    } on AuthException {
      message = 'This verification link is invalid or expired. Please sign in to request a new one.';
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SignInScreen(
          authService: widget.authService,
          initialMessage: message,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground(context),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: authAccentColor),
            const SizedBox(height: 20),
            Text(
              'Verifying your email...',
              style: TextStyle(color: primaryText(context), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
