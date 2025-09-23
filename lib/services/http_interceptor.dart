import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HttpInterceptor {
  static const _storage = FlutterSecureStorage();
  static Function? onSessionExpired;

  /// Realiza una petición GET con manejo automático de expiración
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final token = await _storage.read(key: 'auth_token');

    final finalHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    final response = await http.get(url, headers: finalHeaders);

    if (response.statusCode == 401) {
      await _handleSessionExpired();
    }

    return response;
  }

  /// Realiza una petición POST con manejo automático de expiración
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await _storage.read(key: 'auth_token');

    final finalHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    final response = await http.post(url, headers: finalHeaders, body: body);

    if (response.statusCode == 401) {
      await _handleSessionExpired();
    }

    return response;
  }

  /// Maneja la expiración de sesión
  static Future<void> _handleSessionExpired() async {
    print('🔐 Sesión expirada - redirigiendo al login');

    // Limpiar el storage
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'token_expiry');

    // Llamar al callback si existe
    if (onSessionExpired != null) {
      onSessionExpired!();
    }
  }

  /// Configura el callback para manejar la expiración
  static void setOnSessionExpired(Function callback) {
    onSessionExpired = callback;
  }
}
