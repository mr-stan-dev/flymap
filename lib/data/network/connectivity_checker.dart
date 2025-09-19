import 'dart:io';

class ConnectivityChecker {
  const ConnectivityChecker();

  Future<bool> hasInternetConnectivity({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      final socket = await Socket.connect('8.8.8.8', 53, timeout: timeout);
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }
}
