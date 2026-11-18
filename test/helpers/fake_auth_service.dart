import 'dart:typed_data';

import 'package:seatnix/services/auth_service.dart';

class FakeAuthService implements AuthService {
  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<SignUpResult> signUp({
    required String username,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    return const SignUpResult(requiresCode: false);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> verifyEmailLink({
    required String userId,
    required String secret,
  }) async {}

  @override
  Future<void> verifyEmailCode({
    required String userId,
    required String code,
  }) async {}

  @override
  Future<bool> hasSession() async => false;

  @override
  Future<SeatNixUser?> currentUser() async => null;

  @override
  Future<Uint8List?> currentAvatar() async => null;

  @override
  Future<void> updateProfile({
    required String username,
    required String phoneNumber,
  }) async {}

  @override
  Future<String> updateAvatar({
    required Uint8List bytes,
    required String contentType,
  }) async {
    return 'fake-avatar';
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {}

  @override
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {}

  @override
  Future<void> updatePassword({required String password}) async {}

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {}
}
