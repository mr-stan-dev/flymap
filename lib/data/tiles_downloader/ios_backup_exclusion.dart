import 'dart:io';

import 'package:flutter/services.dart';

/// Keeps large, re-downloadable offline maps out of iCloud/device backups.
///
/// The files remain in durable Application Support storage; this only changes
/// their backup metadata on iOS. Other platforms deliberately do nothing.
class IosBackupExclusion {
  IosBackupExclusion({bool Function()? isIos})
    : _isIos = isIos ?? _platformIsIos;

  static const MethodChannel _channel = MethodChannel(
    'app.flymap/offline_storage',
  );
  static const String _excludeFromBackupMethod = 'excludeFromBackup';

  final bool Function() _isIos;

  Future<void> exclude(String filePath) async {
    if (!_isIos()) return;
    await _channel.invokeMethod<void>(_excludeFromBackupMethod, filePath);
  }

  static bool _platformIsIos() => Platform.isIOS;
}
