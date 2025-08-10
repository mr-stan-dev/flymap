import 'package:flutter/foundation.dart';

class Logger {
  const Logger(this.name);

  final String name;

  void log(String message) {
    if (kDebugMode) {
      final now = DateTime.now();
      final logTime = '(${now.hour}-${now.minute}-${now.second}-${now.millisecond})';
      print('$logTime [$name] $message');
    }
  }

  void error(Object error) => log('[ERROR]: $error');
}
