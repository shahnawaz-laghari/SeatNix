import 'package:flutter/material.dart' hide Text;

import '../services/auth_service.dart';
import '../widgets/localized_text.dart';
import '../services/recent_emails.dart';
import '../widgets/auth_style.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'email_verification_code_screen.dart';
import 'signup_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.authService,
    this.initialMessage,
  });

  final AuthService authService;
  final String? initialMessage;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordController = TextEditingController();
  final _recentEmails = RecentEmails();
  List<String> _savedEmails = [];
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final message = widget.initialMessage;
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr(message))));
      });
    }
    _loadSavedEmails();
  }

  Future<void> _loadSavedEmails() async {
    final emails = await _recentEmails.load();
    if (!mounted) return;
    setState(() => _savedEmails = emails);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _localError() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email';
    }
    if (_passwordController.text.isEmpty) return 'Please enter your password';
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
      await widget.authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await _recentEmails.add(_emailController.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(authService: widget.authService),
        ),
      );
    } on EmailVerificationRequiredException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmailVerificationCodeScreen(
            authService: widget.authService,
            userId: e.userId,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      showAuthError(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openSignUp() async {
    final result = await Navigator.of(context).push<SignUpResult>(
      MaterialPageRoute(
        builder: (_) => SignUpScreen(authService: widget.authService),
      ),
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('Account created. Check your email, verify it, then sign in.'),
          ),
        ),
      );
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
                    SizedBox(height: 48),
                    Text(
                      'Welcome back!',
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
                          'Sign in below or ',
                          style: TextStyle(
                            color: primaryText(context),
                            fontSize: 15,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openSignUp,
                          child: IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'create an account',
                                  style: TextStyle(
                                    color: primaryText(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Container(
                                  height: 1.5,
                                  color: primaryText(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    Text('Email', style: labelStyle),
                    SizedBox(height: 8),
                    RawAutocomplete<String>(
                      textEditingController: _emailController,
                      focusNode: _emailFocus,
                      optionsBuilder: (value) {
                        final query = value.text.trim().toLowerCase();
                        return _savedEmails.where(
                          (email) =>
                              email.toLowerCase().contains(query) &&
                              email.toLowerCase() != query,
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: AlignmentDirectional.topStart,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 220,
                                maxWidth: MediaQuery.sizeOf(context).width - 48,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(
                                      Icons.history,
                                      color: mutedText(context),
                                    ),
                                    title: Text(
                                      option,
                                      style: TextStyle(
                                        color: primaryText(context),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
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
                                if (v.isEmpty) {
                                  return tr('Please enter your email');
                                }
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(v)) {
                                  return tr('Please enter a valid email');
                                }
                                return null;
                              },
                            );
                          },
                    ),
                    SizedBox(height: 20),
                    Text('Password', style: labelStyle),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: [AutofillHints.password],
                      decoration: authFieldDecoration(
                        context,
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: primaryText(context),
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('Please enter your password');
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    Spacer(),
                    SizedBox(height: 32),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
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
                          : Text('Sign In'),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(
                            authService: widget.authService,
                          ),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryText(context),
                      ),
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Forgot password?',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 2),
                            Divider(
                              height: 1.5,
                              thickness: 1.5,
                              color: primaryText(context),
                            ),
                          ],
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
      ),
    );
  }
}
