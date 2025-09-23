import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vira/models/user.dart';
import 'package:vira/services/http_interceptor.dart';

class ScanUser {
  final String nickname;
  final String name;

  ScanUser({required this.nickname, required this.name});

  factory ScanUser.fromJson(Map<String, dynamic> json) {
    return ScanUser(nickname: json['nickname'] ?? '', name: json['name'] ?? '');
  }
}

class AuthService extends ChangeNotifier {
  static const String _baseUrl = 'http://192.168.130.50:9080/api';
  static const _storage = FlutterSecureStorage();

  User? _user;
  String? _token;
  DateTime? _tokenExpiresAt;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _error;
  List<ScanUser> _scanUsers = [];
  bool _loadingUsers = false;
  bool _sessionExpired = false;

  User? get user => _user;
  String? get token => _token;
  DateTime? get tokenExpiresAt => _tokenExpiresAt;
  bool get isAuthenticated =>
      _user != null && _token != null && !_sessionExpired && !isTokenExpired;
  bool get isLoading => _isLoading;
  bool get isLoggingOut => _isLoggingOut;
  String? get error => _error;
  List<ScanUser> get scanUsers => _scanUsers;
  bool get loadingUsers => _loadingUsers;
  bool get sessionExpired => _sessionExpired;
  bool get isTokenExpired =>
      _tokenExpiresAt != null && _tokenExpiresAt!.isBefore(DateTime.now());

  // Verifica si el token expira en menos de 30 minutos (para renovación automática)
  bool get shouldRefreshToken =>
      _tokenExpiresAt != null &&
      _tokenExpiresAt!.difference(DateTime.now()).inMinutes < 30;

  AuthService() {
    _initializeAuth();
    HttpInterceptor.setOnSessionExpired(handleSessionExpired);
  }

  void handleSessionExpired() {
    if (_isLoggingOut) return;

    _sessionExpired = true;
    _user = null;
    _token = null;
    _tokenExpiresAt = null;
    _error =
        'Tu sesión ha expirado por inactividad. Por favor, inicia sesión nuevamente.';
    notifyListeners();
  }

  Future<void> _initializeAuth() async {
    try {
      final storedToken = await _storage.read(key: 'auth_token');
      final storedExpiry = await _storage.read(key: 'token_expiry');

      if (storedToken != null && storedExpiry != null) {
        _token = storedToken;
        _tokenExpiresAt = DateTime.parse(storedExpiry);

        if (isTokenExpired) {
          await _cleanAuth();
          return;
        }

        await _loadUserData();
      }
    } catch (e) {
      await _cleanAuth();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadScanUsers() async {
    try {
      _loadingUsers = true;
      notifyListeners();

      final response = await HttpInterceptor.get(
        Uri.parse('$_baseUrl/scan-users'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersData = jsonDecode(response.body);
        _scanUsers = usersData.map((user) => ScanUser.fromJson(user)).toList();
      } else {
        _error = 'Error al cargar usuarios';
      }
    } catch (e) {
      _error = 'Error de conexión al cargar usuarios';
    } finally {
      _loadingUsers = false;
      notifyListeners();
    }
  }

  Future<bool> login(String login, String password) async {
    try {
      _error = null;
      _isLoading = true;
      _sessionExpired = false;
      notifyListeners();

      final response = await HttpInterceptor.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': login, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        _token = responseData['token'];
        _tokenExpiresAt = DateTime.parse(responseData['expires_at']);
        _user = User.fromJson({
          ...responseData['user'],
          'work_centers': responseData['work_centers'] ?? [],
        });

        await _storage.write(key: 'auth_token', value: _token);
        await _storage.write(
          key: 'token_expiry',
          value: _tokenExpiresAt!.toIso8601String(),
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        _error = error['message'] ?? 'Error de autenticación';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión. Verifica tu internet.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadUserData() async {
    try {
      final response = await HttpInterceptor.get(Uri.parse('$_baseUrl/user'));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _user = User.fromJson(userData);

        if (userData['expires_at'] != null) {
          _tokenExpiresAt = DateTime.parse(userData['expires_at']);
          await _storage.write(
            key: 'token_expiry',
            value: _tokenExpiresAt!.toIso8601String(),
          );
        }
      } else if (response.statusCode == 401) {
        handleSessionExpired();
      }
    } catch (e) {
      // Error silencioso en carga de datos de usuario
    }
  }

  Future<bool> refreshToken() async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$_baseUrl/refresh-token'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _token = responseData['token'];
        _tokenExpiresAt = DateTime.parse(responseData['expires_at']);

        await _storage.write(key: 'auth_token', value: _token);
        await _storage.write(
          key: 'token_expiry',
          value: _tokenExpiresAt!.toIso8601String(),
        );

        notifyListeners();
        return true;
      }
    } catch (e) {
      // Error silencioso en refresh token
    }
    return false;
  }

  Future<void> logout() async {
    try {
      _isLoggingOut = true;
      notifyListeners();

      if (_token != null) {
        await HttpInterceptor.post(Uri.parse('$_baseUrl/logout'));
      }
    } finally {
      await _cleanAuth();
    }
  }

  Future<void> _cleanAuth() async {
    _user = null;
    _token = null;
    _tokenExpiresAt = null;
    _error = null;
    _isLoggingOut = false;
    _sessionExpired = false;
    _scanUsers.clear();
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'token_expiry');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
