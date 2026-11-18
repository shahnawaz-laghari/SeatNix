import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seatnix/screens/signin_screen.dart';
import 'package:seatnix/screens/signup_screen.dart';
import 'package:seatnix/screens/notifications_screen.dart';

import '../helpers/fake_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign in shows a precise error for empty email', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SignInScreen(authService: FakeAuthService())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsWidgets);
  });

  testWidgets('sign in shows a precise error for invalid email', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SignInScreen(authService: FakeAuthService())),
    );
    await tester.pumpAndSettle();

    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, 'not-an-email');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email'), findsWidgets);
  });

  testWidgets('sign up shows the first invalid field error', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(
      MaterialApp(home: SignUpScreen(authService: FakeAuthService())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a username'), findsWidgets);
  });

  testWidgets('notifications screen has All and Transactions tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Welcome to SeatNix'), findsOneWidget);

    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();

    expect(find.text('No transaction notifications yet.'), findsOneWidget);
    expect(find.text('Welcome to SeatNix'), findsNothing);
  });
}
