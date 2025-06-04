import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class AuthService extends ChangeNotifier {
  static const String _baseUrl = 'http://10.1.50.253:8000/api';
  static const _storage = FlutterSecureStorage();

  User? _user;
  String? _token;
  List<WorkCenter> _workCenters = [];
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  List<WorkCenter> get workCenters => _workCenters;
  bool get isAuthenticated => _user != null && _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthService() {
    _initializeAuth();
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

  Future<bool> login(String email, String password) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));

        _user = authResponse.user;
        _token = authResponse.token;
        _workCenters = authResponse.workCenters;

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
      final response = await http.get(
        Uri.parse('$_baseUrl/work-centers'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['user']);
        _workCenters =
            (data['work_centers'] as List)
                .map((item) => WorkCenter.fromJson(item))
                .toList();
      } else if (response.statusCode == 401) {
        await logout();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await http.post(
          Uri.parse('$_baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _user = null;
      _token = null;
      _workCenters = [];
      _error = null;
      await _storage.delete(key: 'auth_token');
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
