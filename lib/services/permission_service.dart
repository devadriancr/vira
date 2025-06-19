import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionService extends ChangeNotifier {
  bool _locationPermissionGranted = false;
  bool _locationServiceEnabled = false;
  bool _permissionsChecked = false;

  bool get locationPermissionGranted => _locationPermissionGranted;
  bool get locationServiceEnabled => _locationServiceEnabled;
  bool get permissionsChecked => _permissionsChecked;

  // Getter que indica si tenemos todos los permisos necesarios
  bool get hasLocationAccess =>
      _locationPermissionGranted && _locationServiceEnabled;

  /// Inicializa y solicita todos los permisos necesarios
  Future<void> initializePermissions() async {
    await _checkAndRequestLocationPermissions();
    _permissionsChecked = true;
    notifyListeners();
  }

  /// Verifica y solicita permisos de ubicación
  Future<void> _checkAndRequestLocationPermissions() async {
    try {
      // 1. Verificar si el servicio de ubicación está habilitado
      _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!_locationServiceEnabled) {
        print("⚠️ El servicio de ubicación está deshabilitado");
        // Opcional: Mostrar diálogo para ir a configuraciones
        await _showLocationServiceDialog();
      }

      // 2. Verificar permisos de ubicación
      PermissionStatus locationStatus = await Permission.location.status;

      if (locationStatus.isDenied) {
        // Solicitar permiso si está denegado
        locationStatus = await Permission.location.request();
      }

      _locationPermissionGranted = locationStatus.isGranted;

      if (locationStatus.isPermanentlyDenied) {
        print("⚠️ Permiso de ubicación denegado permanentemente");
        // Opcional: Mostrar diálogo para ir a configuraciones
        await _showPermissionDialog();
      }

      // 3. Verificar nuevamente el servicio después de solicitar permisos
      _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

      print("✅ Estado de permisos:");
      print(
        "   - Permiso de ubicación: ${_locationPermissionGranted ? 'CONCEDIDO' : 'DENEGADO'}",
      );
      print(
        "   - Servicio de ubicación: ${_locationServiceEnabled ? 'HABILITADO' : 'DESHABILITADO'}",
      );
    } catch (e) {
      print("❌ Error al verificar permisos: $e");
    }
  }

  /// Muestra un diálogo informativo sobre el servicio de ubicación
  Future<void> _showLocationServiceDialog() async {
    print(
      "💡 Se recomienda habilitar el servicio de ubicación para obtener información completa del dispositivo",
    );
  }

  /// Muestra un diálogo informativo sobre permisos
  Future<void> _showPermissionDialog() async {
    print(
      "💡 Se recomienda conceder el permiso de ubicación para obtener información completa del dispositivo",
    );
  }

  /// Abre la configuración de la aplicación
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Verifica el estado actual de los permisos sin solicitarlos
  Future<void> checkPermissionStatus() async {
    _locationPermissionGranted = await Permission.location.isGranted;
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    notifyListeners();
  }

  /// Reintenta solicitar permisos
  Future<void> retryPermissions() async {
    await _checkAndRequestLocationPermissions();
    notifyListeners();
  }
}
