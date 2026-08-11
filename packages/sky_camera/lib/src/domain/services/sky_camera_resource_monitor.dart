enum SkyCameraRecordingResourceIssue { lowStorage, deviceTooHot }

abstract class SkyCameraResourceMonitor {
  Future<SkyCameraRecordingResourceIssue?> currentIssue();
}
