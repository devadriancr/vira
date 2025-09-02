import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vira/models/models.dart';
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
  static const String _baseUrl = 'http://192.168.120.17:8000/api';
  static const _storage = FlutterSecureStorage();

  User? _user;
  String? _token;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _error;
  List<ScanUser> _scanUsers = [];
  bool _loadingUsers = false;
  bool _sessionExpired = false; // Nueva variable para manejar expiración

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated =>
      _user != null && _token != null && !_sessionExpired;
  bool get isLoading => _isLoading;
  bool get isLoggingOut => _isLoggingOut;
  String? get error => _error;
  List<ScanUser> get scanUsers => _scanUsers;
  bool get loadingUsers => _loadingUsers;
  bool get sessionExpired => _sessionExpired;

  AuthService() {
    _initializeAuth();

    // Configurar el callback para manejar expiración de sesión
    HttpInterceptor.setOnSessionExpired(() {
      _handleSessionExpired();
    });
  }

  /// Maneja la expiración de sesión
  void _handleSessionExpired() {
    if (_isLoggingOut) return;

    _sessionExpired = true;
    _user = null;
    _token = null;
    _error =
        'Tu sesión ha expirado por inactividad. Por favor, inicia sesión nuevamente.';
    notifyListeners();
  }

  Future<void> _initializeAuth() async {
    try {
      final storedToken = await _storage.read(key: 'auth_token');
      if (storedToken != null) {
        _token = storedToken;
        await _loadUserData();
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
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
      debugPrint('Error loading scan users: $e');
    } finally {
      _loadingUsers = false;
      notifyListeners();
    }
  }

  Future<bool> login(String login, String password) async {
    try {
      _error = null;
      _isLoading = true;
      _sessionExpired = false; // Resetear el flag de expiración
      notifyListeners();

      final response = await HttpInterceptor.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'login': login, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        _token = responseData['token'];

        // Crear el usuario con los work_centers incluidos en la respuesta
        _user = User.fromJson({
          ...responseData['user'],
          'work_centers': responseData['work_centers'] ?? [],
        });

        await _storage.write(key: 'auth_token', value: _token);

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
      } else if (response.statusCode == 401) {
        // El interceptor ya manejará esto
        return;
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> logout() async {
    try {
      _isLoggingOut = true;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));

      if (_token != null) {
        await HttpInterceptor.post(Uri.parse('$_baseUrl/logout'));
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _user = null;
      _token = null;
      _error = null;
      _isLoggingOut = false;
      _sessionExpired = false;
      _scanUsers.clear();
      await _storage.delete(key: 'auth_token');
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
