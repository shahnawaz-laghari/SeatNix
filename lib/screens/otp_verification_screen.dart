import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';
import 'set_new_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.authService,
    required this.email,
  });

  final AuthService authService;
  final String email;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _codeLength = 6;

  final _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final _focusNodes = List.generate(_codeLength, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var k = 0; k < digits.length && index + k < _codeLength; k++) {
        _controllers[index + k].text = digits[k];
      }
      final last = (index + digits.length).clamp(0, _codeLength - 1);
      _focusNodes[last].requestFocus();
      return;
    }
    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verify() async {
    final code = _code;
    if (code.length != _codeLength) {
      _showMessage(tr('Please enter the 6-digit code'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.authService.verifyRecoveryCode(
        email: widget.email,
        code: code,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SetNewPasswordScreen(authService: widget.authService),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    try {
      await widget.authService.sendPasswordReset(email: widget.email);
      if (!mounted) return;
      _showMessage('A new code has been sent to your email.');
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    }
  }

  Widget _codeBox(int index) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: mutedText(context)),
    );
    return SizedBox(
      width: 46,
      height: 58,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        autofocus: index == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction:
            index == _codeLength - 1 ? TextInputAction.done : TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: _codeLength,
        onChanged: (value) => _onDigitChanged(index, value),
        onSubmitted: (_) {
          if (index == _codeLength - 1) _verify();
        },
        style: TextStyle(
          color: primaryText(context),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.symmetric(vertical: 14),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: primaryText(context), width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 16),
                  authBackButton(context),
                  SizedBox(height: 32),
                  Text(
                    'Enter verification code',
                    style: TextStyle(
                      color: primaryText(context),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    tr(
                      'We sent a 6-digit code to {email}.',
                      {'email': widget.email},
                    ),
                    style: TextStyle(
                      color: mutedText(context),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < _codeLength; i++) _codeBox(i),
                    ],
                  ),
                  Spacer(),
                  SizedBox(height: 32),
                  FilledButton(
                    onPressed: _isLoading ? null : _verify,
                    style: FilledButton.styleFrom(
                      backgroundColor: authAccentColor,
                      foregroundColor: buttonTextColor(context),
                      disabledBackgroundColor:
                          authAccentColor.withValues(alpha: 0.6),
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
                        : Text('Verify'),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: _resendCode,
                    style: TextButton.styleFrom(
                      foregroundColor: primaryText(context),
                    ),
                    child: Text(
                      'Resend code',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
