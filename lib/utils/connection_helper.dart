import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionHelper {
  /// Check if the device has any internet connectivity (Wi-Fi or mobile data)
  static Future<bool> hasNetworkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none) ||
        connectivityResult.isEmpty) {
      return false;
    }

    // optional: do a quick DNS check to verify internet access
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Check if Laravel backend is reachable (simple ping)
  static Future<bool> isBackendReachable(String apiUrl) async {
    try {
      final uri = Uri.parse(apiUrl);
      final socket = await Socket.connect(
        uri.host,
        uri.port,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
