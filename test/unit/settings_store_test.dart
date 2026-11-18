import 'package:flutter_test/flutter_test.dart';
import 'package:seatnix/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults are applied when nothing is stored', () async {
    expect(await SettingsStore.pushNotifications, isTrue);
    expect(await SettingsStore.emailNotifications, isFalse);
    expect(await SettingsStore.showPhone, isFalse);
  });

  test('toggles are persisted independently', () async {
    await SettingsStore.write(SettingsStore.pushNotificationsKey, false);
    await SettingsStore.write(SettingsStore.showPhoneKey, true);

    expect(await SettingsStore.pushNotifications, isFalse);
    expect(await SettingsStore.showPhone, isTrue);
    expect(await SettingsStore.emailNotifications, isFalse);
  });
}
