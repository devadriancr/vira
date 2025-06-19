import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class MaterialValidationController {
  static const String _baseUrl = 'http://10.1.50.253:8000/api';
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> validate(
    String containerCode,
    String visualAidCode,
    String finalLabelCode,
  ) async {
    // 1. Verificar si hay campos vacíos (automáticamente NG)
    if (containerCode.isEmpty ||
        visualAidCode.isEmpty ||
        finalLabelCode.isEmpty) {
      return {
        'isValid': false,
        'partNumber': null,
        'validationComment': 'Uno o más campos están vacíos',
      };
    }

    // 2. Verificar formatos correctos (C- y V-)
    final containerValid =
        containerCode.startsWith('C-') && containerCode.length > 2;
    final visualAidValid =
        visualAidCode.startsWith('V-') && visualAidCode.length > 2;

    if (!containerValid || !visualAidValid) {
      String comment = '';
      if (!containerValid && !visualAidValid) {
        comment =
            'No se ingresaron correctamente el contenedor y la ayuda visual';
      } else if (!containerValid) {
        comment =
            'No se ingresaron correctamente el contenedor, debe empezar con "C-"';
      } else {
        comment =
            'No se ingresaron correctamente la ayuda visual, debe empezar con "V-"';
      }

      return {
        'isValid': false,
        'partNumber': null,
        'validationComment': comment,
      };
    }

    // 3. Extraer códigos base
    final containerBase = containerCode.substring(2);
    final visualAidBase = visualAidCode.substring(2);

    // 4. Determinar el tipo de validación según la presencia de '/'
    return _validateBasedOnCombinations(
      containerBase,
      visualAidBase,
      finalLabelCode,
    );
  }

  /// Valida según los diferentes casos de combinaciones
  static Map<String, dynamic> _validateBasedOnCombinations(
    String containerBase,
    String visualAidBase,
    String finalLabelCode,
  ) {
    final containerHasSlash = containerBase.contains('/');
    final visualAidHasSlash = visualAidBase.contains('/');

    if (containerHasSlash && visualAidHasSlash) {
      // Caso 2: Ambos tienen '/', validar coincidencia directa
      return _validateDirectMatch(containerBase, visualAidBase, finalLabelCode);
    } else if (containerHasSlash && !visualAidHasSlash) {
      // Caso 1: Solo contenedor tiene '/', generar combinaciones
      return _validateWithCombinations(
        containerBase,
        visualAidBase,
        finalLabelCode,
      );
    } else {
      // Caso original: Sin '/', validación tradicional
      return _validateTraditional(containerBase, visualAidBase, finalLabelCode);
    }
  }

  /// Caso 2: Validación directa cuando ambos tienen '/'
  static Map<String, dynamic> _validateDirectMatch(
    String containerBase,
    String visualAidBase,
    String finalLabelCode,
  ) {
    // Verificar coincidencia exacta
    if (containerBase != visualAidBase) {
      return {
        'isValid': false,
        'partNumber': null,
        'validationComment':
            'El número de parte del contenedor y ayuda visual no coinciden',
      };
    }

    // Buscar el texto completo en la etiqueta final
    final containsPart = finalLabelCode.contains(containerBase);
    return {
      'isValid': containsPart,
      'partNumber': containsPart ? containerBase : null,
      'validationComment':
          containsPart
              ? null
              : 'El número de parte "$containerBase" no se encuentra en la etiqueta final',
    };
  }

  /// Caso 1: Validación con combinaciones cuando solo el contenedor tiene '/'
  static Map<String, dynamic> _validateWithCombinations(
    String containerBase,
    String visualAidBase,
    String finalLabelCode,
  ) {
    // Generar combinaciones del contenedor
    final combinations = _generateCombinations(containerBase);

    // Verificar si alguna combinación coincide con la ayuda visual
    for (final combination in combinations) {
      if (combination == visualAidBase) {
        // Buscar esta combinación en la etiqueta final
        final containsPart = finalLabelCode.contains(combination);
        return {
          'isValid': containsPart,
          'partNumber': containsPart ? combination : null,
          'validationComment':
              containsPart
                  ? null
                  : 'El número de parte "$combination" no se encuentra en la etiqueta final',
        };
      }
    }

    return {
      'isValid': false,
      'partNumber': null,
      'validationComment':
          'El número de parte de la ayuda visual "$visualAidBase" no coincide con ninguna combinación del contenedor',
    };
  }

  /// Caso original: Validación tradicional sin '/'
  static Map<String, dynamic> _validateTraditional(
    String containerBase,
    String visualAidBase,
    String finalLabelCode,
  ) {
    // Verificar coincidencia de códigos base
    if (containerBase != visualAidBase) {
      return {
        'isValid': false,
        'partNumber': null,
        'validationComment':
            'El número de parte del contenedor "$containerBase" y ayuda visual "$visualAidBase" no coinciden',
      };
    }

    // Verificar que el código base esté en la etiqueta final
    final containsPart = finalLabelCode.contains(containerBase);
    return {
      'isValid': containsPart,
      'partNumber': containsPart ? containerBase : null,
      'validationComment':
          containsPart
              ? null
              : 'El número de parte "$containerBase" no se encuentra en la etiqueta final',
    };
  }

  /// Genera combinaciones a partir de un código con '/'
  /// Ejemplo: "BDTT/BDTS70500" → ["BDTT70500", "BDTS70500"]
  static List<String> _generateCombinations(String code) {
    if (!code.contains('/')) {
      return [code];
    }

    final parts = code.split('/');
    if (parts.length != 2) {
      return [code]; // Si no es exactamente 2 partes, devolver original
    }

    final prefix1 = parts[0];
    final prefix2AndSuffix = parts[1];

    // Encontrar donde termina el segundo prefijo
    // Asumimos que el sufijo son los caracteres numéricos al final
    String prefix2 = '';
    String suffix = '';

    // Separar el segundo prefijo del sufijo
    final match = RegExp(r'^([A-Za-z]+)(.*)$').firstMatch(prefix2AndSuffix);
    if (match != null) {
      prefix2 = match.group(1)!;
      suffix = match.group(2)!;
    } else {
      // Si no se puede separar, usar toda la cadena como prefix2
      prefix2 = prefix2AndSuffix;
      suffix = '';
    }

    return [prefix1 + suffix, prefix2 + suffix];
  }

  static Future<List<String>?> sendValidationToAPI({
    required String containerCode,
    required String visualAidCode,
    required String finalLabelCode,
    required bool isValid,
    required String? partNumber,
    required String? validationComment,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // Obtener información del dispositivo
      final deviceInfo = DeviceInfoPlugin();
      String deviceModel = 'Desconocido';
      String deviceName = 'Desconocido';
      String deviceId = 'Desconocido';

      if (Platform.isAndroid) {
        AndroidDeviceInfo android = await deviceInfo.androidInfo;
        deviceId = android.id;
        deviceModel = android.model;
        deviceName = android.device;
      } else if (Platform.isIOS) {
        IosDeviceInfo ios = await deviceInfo.iosInfo;
        deviceId = ios.identifierForVendor ?? 'Desconocido';
        deviceModel = ios.model;
        deviceName = ios.name;
      }

      // ✅ Verificar permisos ya solicitados (no los pedimos aquí)
      final locationPermission = await Permission.location.isGranted;
      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();

      if (!locationPermission) {
        print("⚠️ Permiso de ubicación no concedido previamente.");
      }

      if (!isLocationEnabled) {
        print("⚠️ La ubicación del dispositivo está desactivada.");
      }

      // ✅ Obtener IP y MAC (BSSID del router Wi-Fi)
      final networkInfo = NetworkInfo();
      String? ipAddress = await networkInfo.getWifiIP();
      String? macAddress =
          (locationPermission && isLocationEnabled)
              ? await networkInfo.getWifiBSSID()
              : null;

      // 🌐 Enviar datos al backend
      final body = {
        'container_code': containerCode,
        'visual_aid_code': visualAidCode,
        'final_label_code': finalLabelCode,
        'validation_status': isValid ? 'OK' : 'NG',
        'part_number': partNumber,
        'device_model': deviceModel,
        'device_name': deviceName,
        'device_id': deviceId,
        'ip_address': ipAddress,
        'mac_address': macAddress?.toUpperCase(),
      };

      if (validationComment != null) {
        body['validation_comment'] = validationComment;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/material-validations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Validación enviada exitosamente: ${data['message']}');
        if (data['access_errors'] != null) {
          return List<String>.from(data['access_errors']);
        }
      } else if (response.statusCode == 422) {
        final error = jsonDecode(response.body);
        throw Exception('Error de validación: ${error['message']}');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes acceso a este centro de trabajo');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error enviando validación a la API: $e');
      rethrow;
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>> getValidationHistory({
    int? workCenterId,
    String? status,
    int limit = 50,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final queryParams = <String, String>{'limit': limit.toString()};

      if (workCenterId != null) {
        queryParams['work_center_id'] = workCenterId.toString();
      }

      if (status != null) {
        queryParams['validation_status'] = status;
      }

      final uri = Uri.parse(
        '$_baseUrl/material-validations',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
          'Error al obtener el historial: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error obteniendo historial: $e');
      rethrow;
    }
  }
}
