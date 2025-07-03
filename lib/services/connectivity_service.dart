import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum ConnectivityStatus { checking, connected, disconnected }

class ConnectivityService extends ChangeNotifier {
  static const String _baseUrl = 'http://192.168.130.50:9080/api';
  static const Duration _timeout = Duration(seconds: 10);

  ConnectivityStatus _status = ConnectivityStatus.checking;

  ConnectivityStatus get status => _status;
  bool get isConnected => _status == ConnectivityStatus.connected;

  ConnectivityService() {
    checkConnectivity();
  }

  Future<void> checkConnectivity() async {
    _status = ConnectivityStatus.checking;
    notifyListeners();

    try {
      final hasInternet = await InternetAddress.lookup('google.com')
          .timeout(_timeout)
          .then(
            (result) => result.isNotEmpty && result[0].rawAddress.isNotEmpty,
          )
          .catchError((_) => false);

      if (!hasInternet) {
        _status = ConnectivityStatus.disconnected;
        notifyListeners();
        return;
      }

      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(_timeout);

      _status =
          response.statusCode == 200
              ? ConnectivityStatus.connected
              : ConnectivityStatus.disconnected;
    } catch (_) {
      _status = ConnectivityStatus.disconnected;
    }

    notifyListeners();
  }
}
