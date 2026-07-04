import 'dart:ui';

import 'package:share_plus/share_plus.dart';

abstract interface class AppShareService {
  Future<bool> shareApp({required Rect sharePositionOrigin});
}

class DefaultAppShareService implements AppShareService {
  static const String _appUrl = 'https://flymap.app';

  @override
  Future<bool> shareApp({required Rect sharePositionOrigin}) async {
    try {
      final result = await Share.share(
        'Explore your flight from the window seat with Flymap.\n$_appUrl',
        sharePositionOrigin: sharePositionOrigin,
      );
      return result.status == ShareResultStatus.success;
    } catch (_) {
      return false;
    }
  }
}
