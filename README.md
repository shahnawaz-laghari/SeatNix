# SeatNix

SeatNix is a Flutter bus-seat booking app. It lets users search routes, choose a
departure time and seat, complete a simulated payment, and keep an e-ticket and
travel history on their device. The app supports English and Urdu (RTL) and
light, dark, and system themes.

> **Status:** the booking and payment flow is a UI demonstration. Payments are
> simulated and no real tickets are issued.

## Features

- **Authentication** — email/password sign-up and sign-in with Appwrite, email
  verification, and password recovery by 6-digit code.
- **Booking flow** — route search, Today / Tomorrow / Other departures, seat map
  with available, selected, and filled seats, and a countdown to departure.
- **Payments (UI only)** — EasyPaisa, JazzCash, and debit/credit card options
  with payment-detail entry. Card details are never stored in full.
- **Tickets and history** — e-ticket screen with a PNG download, travel history
  with multi-select and deletion, and a separate last-payment summary.
- **Profile** — avatar upload, editable name and phone number, change password,
  and device-specific preferences.
- **Notifications** — All and Transactions tabs.
- **Localization** — English and Urdu, with RTL layout support.
- **Theming** — System, Light, and Dark modes applied across every screen.

## Tech stack

- Flutter / Dart
- Appwrite (authentication, account preferences, file storage, tables)
- `shared_preferences` for local cache and settings
- `file_saver` for saving e-ticket images
- `audioplayers` and `flutter_local_notifications`

## Project structure

```
lib/
  config/       backend IDs (public endpoint and project ID only)
  l10n/         Urdu translations
  models/       Trip model
  screens/      UI screens
  services/     auth, storage, settings, notifications, sound, theme, language
  utils/        web helpers
  widgets/      shared styles and localized Text
assets/
  animation/    splash animation
  audio/        success chime
  images/       branding and payment-method logos
test/
  unit/         pure Dart unit tests
  widget/       UI/widget tests
```

## Getting started

### Prerequisites

- Flutter SDK (Dart 3.13 or newer)
- An Android SDK for Android builds, or a browser for web builds

### Setup

```bash
flutter pub get
flutter analyze
flutter test
```

Run on a connected device or browser:

```bash
flutter run -d chrome
```

## Building

```bash
# Android release APK
flutter build apk --release

# Web release build
flutter build web --release
```

The Android package name is `com.seatnix.app`.

## Backend configuration

The public Appwrite endpoint and project ID live in
`lib/config/appwrite_config.dart`. No API keys or secrets belong in the app,
assets, or source control.

See [APPWRITE_SETUP.md](APPWRITE_SETUP.md) for the database, table, storage
bucket, and platform configuration used by this project.

## Testing

```bash
flutter analyze       # static analysis
flutter test          # 22 unit and widget tests
```

## Security note

Any credentials that were shared in chat or committed previously should be
considered exposed. Revoke and replace them in Appwrite and Safepay before
using those accounts in production.

## License

Private project. No license is granted for reuse or redistribution.
