import 'package:flutter/material.dart' hide Text;

import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.titleKey,
    required this.sections,
  });

  final String titleKey;
  final List<({String titleKey, String bodyKey})> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground(context),
      appBar: AppBar(
        backgroundColor: screenBackground(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            directionalBackIcon(context),
            textDirection: TextDirection.ltr,
            color: primaryText(context),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          titleKey,
          style: TextStyle(
            color: primaryText(context),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.titleKey,
                  style: TextStyle(
                    color: authAccentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  section.bodyKey,
                  style: TextStyle(
                    color: mutedText(context),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

const privacyPolicySections = <({String titleKey, String bodyKey})>[
  (
    titleKey: 'Information we collect',
    bodyKey: 'We collect the name, email address and phone number you provide when you create an account, plus the travel routes, seats and payment summaries associated with your bookings.',
  ),
  (
    titleKey: 'How we use your information',
    bodyKey: 'Your information is used to create and manage your account, show your travel and payment history, and send important service messages such as booking confirmations.',
  ),
  (
    titleKey: 'Payment information',
    bodyKey: 'During testing, payments are simulated. We never store your full card number or security code. Only the cardholder name, expiry date and last four digits are saved for display.',
  ),
  (
    titleKey: 'Data storage',
    bodyKey: 'Account data is stored by our authentication provider. Travel and payment summaries are also cached on your device so you can view them offline.',
  ),
  (
    titleKey: 'Your choices',
    bodyKey: 'You can delete saved trips from Travel History at any time, and you can control notification and visibility preferences in Settings.',
  ),
];

const termsSections = <({String titleKey, String bodyKey})>[
  (
    titleKey: 'Using SeatNix',
    bodyKey: 'SeatNix helps you find routes, choose seats and keep a record of your trips. You must provide accurate account information and keep your password secure.',
  ),
  (
    titleKey: 'Bookings and payments',
    bodyKey: 'The payment flow in this version is a demonstration. No real money is charged and no real ticket is issued. Live payments will be introduced in a future release.',
  ),
  (
    titleKey: 'Seat availability',
    bodyKey: 'Seat information shown in the app is sample data. Always confirm your seat and travel details with the operator before departure.',
  ),
  (
    titleKey: 'Acceptable use',
    bodyKey: 'Do not attempt to interfere with the app, access other accounts, or use the service for unlawful purposes.',
  ),
  (
    titleKey: 'Changes to these terms',
    bodyKey: 'These terms may be updated as the app develops. Continued use of SeatNix after an update means you accept the revised terms.',
  ),
];
