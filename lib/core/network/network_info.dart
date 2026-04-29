import 'dart:io';

/// Checks device network connectivity by attempting a DNS lookup.
class NetworkInfo {
  NetworkInfo._();

  /// Returns true if the device can reach the internet.
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  /// Throws a [NetworkException] if offline.
  static Future<void> requireConnectivity() async {
    if (!await isConnected()) {
      throw Exception('No internet connection. Please check your network.');
    }
  }
}
