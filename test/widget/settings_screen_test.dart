import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seatnix/screens/settings_screen.dart';

import '../helpers/fake_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(authService: FakeAuthService())),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapRow(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.scrollUntilVisible(finder, 200);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('shows every settings option', (tester) async {
    await pumpSettings(tester);

    for (final label in [
      'Push notifications',
      'Email notifications',
      'Show phone number',
      'Change password',
      'Theme',
      'Customer service',
      'Language',
      'Privacy policy',
      'Terms of service',
      'App version',
    ]) {
      await tester.scrollUntilVisible(find.text(label), 200);
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('opens the privacy policy document', (tester) async {
    await pumpSettings(tester);
    await tapRow(tester, 'Privacy policy');

    expect(find.text('Information we collect'), findsOneWidget);
    expect(find.text('Your choices'), findsOneWidget);
  });

  testWidgets('opens the terms of service document', (tester) async {
    await pumpSettings(tester);
    await tapRow(tester, 'Terms of service');

    expect(find.text('Using SeatNix'), findsOneWidget);
    expect(find.text('Acceptable use'), findsOneWidget);
  });

  testWidgets('opens change password screen', (tester) async {
    await pumpSettings(tester);
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();

    expect(find.text('Current password'), findsOneWidget);
    expect(find.text('New password'), findsOneWidget);
    expect(find.text('Update password'), findsOneWidget);
  });

  testWidgets('shows app version information', (tester) async {
    await pumpSettings(tester);
    await tapRow(tester, 'App version');

    expect(find.text('SeatNix'), findsWidgets);
    expect(find.textContaining('Version'), findsOneWidget);
  });

  testWidgets('theme row opens a chooser with all modes', (tester) async {
    await pumpSettings(tester);
    await tapRow(tester, 'Theme');

    expect(find.text('System'), findsWidgets);
    expect(find.text('Light'), findsWidgets);
    expect(find.text('Dark'), findsWidgets);
  });

  testWidgets('language row offers English and Urdu', (tester) async {
    await pumpSettings(tester);
    await tapRow(tester, 'Language');

    expect(find.text('English'), findsWidgets);
    expect(find.text('اردو'), findsWidgets);
  });
}
