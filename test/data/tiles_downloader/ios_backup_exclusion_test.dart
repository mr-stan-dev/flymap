import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/tiles_downloader/ios_backup_exclusion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app.flymap/offline_storage');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('sends the final MBTiles path to iOS', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return null;
        });

    final exclusion = IosBackupExclusion(isIos: () => true);
    await exclusion.exclude('/support/mbtiles/flight.mbtiles');

    expect(receivedCall?.method, 'excludeFromBackup');
    expect(receivedCall?.arguments, '/support/mbtiles/flight.mbtiles');
  });

  test('does not invoke the native channel outside iOS', () async {
    var invocationCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          invocationCount++;
          return null;
        });

    final exclusion = IosBackupExclusion(isIos: () => false);
    await exclusion.exclude('/support/mbtiles/flight.mbtiles');

    expect(invocationCount, 0);
  });
}
