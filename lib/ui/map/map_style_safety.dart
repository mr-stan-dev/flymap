import 'package:flutter/services.dart';

bool isStaleStylePlatformException(Object error) {
  if (error is! PlatformException) {
    return false;
  }

  final normalized = <String?>[
    error.code,
    error.message,
    '${error.details}',
  ].whereType<String>().join(' ').toLowerCase();
  return normalized.contains('newer style is loading/has loaded');
}
