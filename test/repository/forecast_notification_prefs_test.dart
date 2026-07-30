import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/repository/forecast_notification_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('both alerts default ON', () async {
    final prefs = ForecastNotificationPrefs();
    expect(await prefs.isReadyEnabled(), isTrue);
    expect(await prefs.isUpdatedEnabled(), isTrue);
  });

  test('toggles persist independently', () async {
    final prefs = ForecastNotificationPrefs();
    await prefs.setReadyEnabled(false);

    expect(await prefs.isReadyEnabled(), isFalse);
    expect(await prefs.isUpdatedEnabled(), isTrue);

    await prefs.setUpdatedEnabled(false);
    await prefs.setReadyEnabled(true);

    expect(await prefs.isReadyEnabled(), isTrue);
    expect(await prefs.isUpdatedEnabled(), isFalse);
  });
}
