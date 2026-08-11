import 'package:flutter/services.dart';
import 'package:sky_camera/src/domain/services/sky_camera_resource_monitor.dart';

class DeviceSkyCameraResourceMonitor implements SkyCameraResourceMonitor {
  const DeviceSkyCameraResourceMonitor({
    this.minimumAvailableStorageBytes = defaultMinimumAvailableStorageBytes,
  });

  static const int defaultMinimumAvailableStorageBytes = 512 * 1024 * 1024;
  static const MethodChannel _channel = MethodChannel('app.flymap/video_tools');

  final int minimumAvailableStorageBytes;

  @override
  Future<SkyCameraRecordingResourceIssue?> currentIssue() async {
    final status = await _channel.invokeMapMethod<String, Object?>(
      'getCaptureResourceStatus',
    );
    final availableStorageBytes = (status?['availableStorageBytes'] as num?)
        ?.toInt();
    if (availableStorageBytes != null &&
        availableStorageBytes < minimumAvailableStorageBytes) {
      return SkyCameraRecordingResourceIssue.lowStorage;
    }
    if (status?['isTooHot'] == true) {
      return SkyCameraRecordingResourceIssue.deviceTooHot;
    }
    return null;
  }
}
