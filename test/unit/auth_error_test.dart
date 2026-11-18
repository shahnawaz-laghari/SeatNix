import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seatnix/services/auth_service.dart';

void main() {
  group('friendlyAuthMessage', () {
    test('maps invalid credentials to a precise message', () {
      final error = AppwriteException(
        'Invalid credentials',
        401,
        'user_invalid_credentials',
      );
      expect(
        friendlyAuthMessage(error),
        'The email or password you entered is incorrect.',
      );
    });

    test('maps unknown email to a precise message', () {
      final error = AppwriteException('User not found', 404, 'user_not_found');
      expect(
        friendlyAuthMessage(error),
        'No account was found for this email address.',
      );
    });

    test('maps duplicate email to a precise message', () {
      final error = AppwriteException(
        'User already exists',
        409,
        'user_already_exists',
      );
      expect(friendlyAuthMessage(error), contains('already exists'));
    });

    test('maps short password to a length message', () {
      final error = AppwriteException(
        'Password is too short',
        400,
        'user_password_invalid',
      );
      expect(
        friendlyAuthMessage(error),
        'Your password must be at least 8 characters long.',
      );
    });

    test('maps rate limits and network errors', () {
      expect(
        friendlyAuthMessage(
          AppwriteException('Rate limit exceeded', 429, 'general_rate_limit'),
        ),
        contains('Too many attempts'),
      );
      expect(
        friendlyAuthMessage(
          AppwriteException('Failed host lookup', null, 'network'),
        ),
        contains('No internet connection'),
      );
    });

    test('falls back to the server message for unknown errors', () {
      final error = AppwriteException('Custom server detail', 500, 'unknown');
      expect(friendlyAuthMessage(error), 'Custom server detail');
    });
  });
}
