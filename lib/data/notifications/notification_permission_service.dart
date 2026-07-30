import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper over the system notification permission so UI can check
/// and request it without binding to the plugin (and tests can fake it).
class NotificationPermissionService {
  Future<bool> isGranted() async =>
      (await Permission.notification.status).isGranted;

  /// Requests the permission; falls through to the app settings when it is
  /// permanently denied (the system dialog can no longer appear). Returns
  /// the fresh granted state.
  Future<bool> request() async {
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }
}
