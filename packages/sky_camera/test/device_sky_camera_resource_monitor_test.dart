import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.flymap/video_tools');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reports low storage below the configured reserve', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          return <String, Object>{
            'availableStorageBytes': 99,
            'isTooHot': false,
          };
        });

    const monitor = DeviceSkyCameraResourceMonitor(
      minimumAvailableStorageBytes: 100,
    );

    expect(
      await monitor.currentIssue(),
      SkyCameraRecordingResourceIssue.lowStorage,
    );
  });

  test('reports serious thermal pressure', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          return <String, Object>{
            'availableStorageBytes': 1000,
            'isTooHot': true,
          };
        });

    const monitor = DeviceSkyCameraResourceMonitor(
      minimumAvailableStorageBytes: 100,
    );

    expect(
      await monitor.currentIssue(),
      SkyCameraRecordingResourceIssue.deviceTooHot,
    );
  });
}
