import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';
import 'appwrite_backend.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class EmailVerificationRequiredException extends AuthException {
  const EmailVerificationRequiredException(this.userId)
    : super(
        'Your email is not verified yet. Enter the code we just emailed you.',
      );

  final String userId;
}

class SignUpResult {
  const SignUpResult({required this.requiresCode, this.userId});

  final bool requiresCode;
  final String? userId;
}

/// Converts raw Appwrite errors into direct, user-friendly messages that name
/// the actual problem instead of showing a generic failure.
String friendlyAuthMessage(AppwriteException error) {
  final type = (error.type ?? '').toLowerCase();
  final message = (error.message ?? '').toLowerCase();

  if (type.contains('invalid_credentials') ||
      message.contains('invalid credentials')) {
    return 'The email or password you entered is incorrect.';
  }
  if (type.contains('user_not_found') || message.contains('user not found')) {
    return 'No account was found for this email address.';
  }
  if (type.contains('already_exists') || type.contains('duplicate')) {
    return 'An account with this email already exists. Try signing in instead.';
  }
  if (type.contains('email') && type.contains('invalid')) {
    return 'The email address you entered is not valid.';
  }
  if (type.contains('password') || message.contains('password')) {
    if (message.contains('short') || message.contains('length')) {
      return 'Your password must be at least 8 characters long.';
    }
    return 'Your password does not meet the required rules. Try a stronger one.';
  }
  if (type.contains('rate_limit') || message.contains('rate limit')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (type.contains('network') || message.contains('failed host lookup')) {
    return 'No internet connection. Check your connection and try again.';
  }
  if (error.code == 401) {
    return 'Your session has expired. Please sign in again.';
  }
  return error.message ?? 'Something went wrong. Please try again.';
}

class SeatNixUser {
  const SeatNixUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.emailVerified,
  });

  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final bool emailVerified;
}

abstract class AuthService {
  Future<void> signIn({required String email, required String password});

  Future<SignUpResult> signUp({
    required String username,
    required String phoneNumber,
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<void> verifyEmailLink({
    required String userId,
    required String secret,
  });

  Future<void> verifyEmailCode({required String userId, required String code});

  Future<bool> hasSession();

  Future<SeatNixUser?> currentUser();

  Future<Uint8List?> currentAvatar();

  Future<void> updateProfile({
    required String username,
    required String phoneNumber,
  });

  Future<String> updateAvatar({
    required Uint8List bytes,
    required String contentType,
  });

  Future<void> sendPasswordReset({required String email});

  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  });

  Future<void> updatePassword({required String password});
}

class AppwriteAuthService implements AuthService {
  static SeatNixUser? cachedUser;
  static Uint8List? cachedAvatar;

  String? _recoveryUserId;
  String? _recoveryCode;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await AppwriteBackend.account.createEmailPasswordSession(
        email: email.trim(),
        password: password,
      );
      final user = await AppwriteBackend.account.get();
      if (!user.emailVerification) {
        String? verificationUserId;
        try {
          if (kIsWeb) {
            await _sendVerificationLink();
          } else {
            verificationUserId =
                (await AppwriteBackend.account.createEmailVerificationOTP())
                    .userId;
          }
        } finally {
          try {
            await AppwriteBackend.account.deleteSession(sessionId: 'current');
          } on AppwriteException {
            // The user will still be blocked from app screens until verified.
          }
          cachedUser = null;
        }
        if (verificationUserId != null) {
          throw EmailVerificationRequiredException(verificationUserId);
        }
        throw const AuthException(
          'Please verify your email. We sent you a new verification link.',
        );
      }
      _cacheUser(user);
    } on AppwriteException catch (e) {
      throw AuthException(friendlyAuthMessage(e));
    }
  }

  @override
  Future<SignUpResult> signUp({
    required String username,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    try {
      final user = await AppwriteBackend.account.create(
        userId: ID.unique(),
        email: email.trim(),
        password: password,
        name: username.trim(),
      );
      await AppwriteBackend.account.createEmailPasswordSession(
        email: email.trim(),
        password: password,
      );
      try {
        await AppwriteBackend.account.updatePrefs(
          prefs: {...user.prefs.data, 'phone_number': phoneNumber.trim()},
        );
        if (kIsWeb) {
          await _sendVerificationLink();
          return const SignUpResult(requiresCode: false);
        }
        final token = await AppwriteBackend.account
            .createEmailVerificationOTP();
        return SignUpResult(requiresCode: true, userId: token.userId);
      } finally {
        try {
          await AppwriteBackend.account.deleteSession(sessionId: 'current');
        } on AppwriteException {
          // Ignore cleanup failure; email verification still gates the account.
        }
        cachedUser = null;
        cachedAvatar = null;
      }
    } on AppwriteException catch (e) {
      throw AuthException(friendlyAuthMessage(e));
    }
  }

  String get _verificationRedirectUrl {
    final uri = Uri.base;
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: '/',
    ).toString();
  }

  Future<void> _sendVerificationLink() async {
    await AppwriteBackend.account.createEmailVerification(
      url: _verificationRedirectUrl,
    );
  }

  @override
  Future<void> logout() async {
    try {
      await AppwriteBackend.account.deleteSession(sessionId: 'current');
      cachedUser = null;
      cachedAvatar = null;
    } on AppwriteException catch (e) {
      throw AuthException(e.message ?? 'Could not sign out.');
    }
  }

  @override
  Future<bool> hasSession() async {
    try {
      return await currentUser() != null;
    } on AppwriteException {
      return false;
    }
  }

  @override
  Future<SeatNixUser?> currentUser() async {
    try {
      final user = await AppwriteBackend.account.get();
      if (!user.emailVerification) {
        try {
          await AppwriteBackend.account.deleteSession(sessionId: 'current');
        } on AppwriteException {
          // The next login will still be gated by the verification check.
        }
        cachedUser = null;
        return null;
      }
      return _cacheUser(user);
    } on AppwriteException catch (e) {
      if (e.code == 401) return null;
      throw AuthException(e.message ?? 'Could not load your account.');
    }
  }

  SeatNixUser _cacheUser(appwrite_models.User user) {
    final profile = SeatNixUser(
      id: user.$id,
      name: user.name,
      email: user.email,
      phoneNumber: user.prefs.data['phone_number'] as String? ?? user.phone,
      emailVerified: user.emailVerification,
    );
    cachedUser = profile;
    return profile;
  }

  @override
  Future<void> verifyEmailLink({
    required String userId,
    required String secret,
  }) async {
    try {
      await AppwriteBackend.account.updateEmailVerification(
        userId: userId,
        secret: secret,
      );
    } on AppwriteException catch (e) {
      throw AuthException(
        e.message ?? 'This verification link is invalid or has expired.',
      );
    }
  }

  @override
  Future<void> verifyEmailCode({
    required String userId,
    required String code,
  }) async {
    try {
      await AppwriteBackend.account.updateEmailVerificationOTP(
        userId: userId,
        secret: code.trim(),
      );
    } on AppwriteException catch (e) {
      throw AuthException(
        e.message ?? 'The verification code is invalid or expired.',
      );
    }
  }

  @override
  Future<Uint8List?> currentAvatar() async {
    try {
      final user = await AppwriteBackend.account.get();
      final fileId = user.prefs.data['avatarFileId'] as String?;
      if (fileId == null || fileId.isEmpty) {
        cachedAvatar = null;
        return null;
      }
      final bytes = await AppwriteBackend.storage.getFileView(
        bucketId: AppwriteConfig.avatarBucketId,
        fileId: fileId,
      );
      cachedAvatar = bytes;
      return bytes;
    } on AppwriteException {
      return null;
    }
  }

  @override
  Future<void> updateProfile({
    required String username,
    required String phoneNumber,
  }) async {
    try {
      final user = await AppwriteBackend.account.get();
      await AppwriteBackend.account.updateName(name: username.trim());
      await AppwriteBackend.account.updatePrefs(
        prefs: {...user.prefs.data, 'phone_number': phoneNumber.trim()},
      );
      await currentUser();
    } on AppwriteException catch (e) {
      throw AuthException(e.message ?? 'Could not update your profile.');
    }
  }

  @override
  Future<String> updateAvatar({
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      throw const AuthException('Choose an image smaller than 5 MB.');
    }
    try {
      final user = await AppwriteBackend.account.get();
      final oldFileId = user.prefs.data['avatarFileId'] as String?;
      final isPng = contentType.toLowerCase() == 'image/png';
      final file = await AppwriteBackend.storage.createFile(
        bucketId: AppwriteConfig.avatarBucketId,
        fileId: ID.unique(),
        file: InputFile.fromBytes(
          bytes: bytes,
          filename: isPng ? 'avatar.png' : 'avatar.jpg',
          contentType: isPng ? 'image/png' : 'image/jpeg',
        ),
        permissions: [
          Permission.read(Role.user(user.$id)),
          Permission.update(Role.user(user.$id)),
          Permission.delete(Role.user(user.$id)),
        ],
      );
      await AppwriteBackend.account.updatePrefs(
        prefs: {...user.prefs.data, 'avatarFileId': file.$id},
      );
      if (oldFileId != null && oldFileId.isNotEmpty) {
        try {
          await AppwriteBackend.storage.deleteFile(
            bucketId: AppwriteConfig.avatarBucketId,
            fileId: oldFileId,
          );
        } on AppwriteException {
          // A stale photo should not prevent the profile update from succeeding.
        }
      }
      await currentAvatar();
      return file.$id;
    } on AppwriteException catch (e) {
      throw AuthException(e.message ?? 'Could not upload your photo.');
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      final token = await AppwriteBackend.account.createRecoveryOTP(
        email: email.trim(),
      );
      _recoveryUserId = token.userId;
      _recoveryCode = null;
    } on AppwriteException catch (e) {
      throw AuthException(e.message ?? 'Could not send the recovery code.');
    }
  }

  @override
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    if (email.trim().isEmpty) {
      throw const AuthException('Enter the email address used for recovery.');
    }
    if (_recoveryUserId == null) {
      throw const AuthException('Request a new recovery code and try again.');
    }
    _recoveryCode = code.trim();
  }

  @override
  Future<void> updatePassword({required String password}) async {
    final userId = _recoveryUserId;
    final code = _recoveryCode;
    if (userId == null || code == null) {
      throw const AuthException('Request and enter a recovery code first.');
    }
    try {
      await AppwriteBackend.account.updateRecoveryOTP(
        userId: userId,
        secret: code,
        password: password,
      );
      _recoveryUserId = null;
      _recoveryCode = null;
    } on AppwriteException catch (e) {
      throw AuthException(e.message ?? 'Could not reset your password.');
    }
  }
}
