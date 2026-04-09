import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vira/services/http_interceptor.dart';

class MaterialValidationController {
  static const String _baseUrl = 'http://192.168.130.50:9080/api';

  /// Valida los códigos de material según las reglas de negocio
  static Future<Map<String, dynamic>> validate(
    String containerCode,
    String visualAidCode,
    String finalLabelCode,
  ) async {
    // 1. Verificar longitud mínima de etiqueta final
    if (finalLabelCode.length <= 30) {
      return {
        'isValid': false,
        'partNumber': null,
        'validationComment': 'Orden Incorrecto',
      };
    }

    // 2. Verificar si hay campos vacíos (automáticamente NG)
    if (containerCode.isEmpty ||
        visualAidCode.isEmpty ||
        finalLabelCode.isEmpty) {
      return {
        'isValid': false,
        'partNumber': null,
        'validationComment': 'Orden Incorrecto',
      };
    }

    // 3. Verificar formatos correctos (C- y V-)
    final containerValid =
        containerCode.startsWith('C-') && containerCode.length > 2;
    final visualAidValid =
        visualAidCode.startsWith('V-') && visualAidCode.length > 2;

    if (!containerValid || !visualAidValid) {
      return {
        'isValid': false,
        'partNumber': null,
        'validationComment': 'Orden Incorrecto',
      };
    }

    // 4. Verificar que finalLabelCode NO inicie con C- o V-
    final finalLabelStartsWithC = finalLabelCode.startsWith('C-');
    final finalLabelStartsWithV = finalLabelCode.startsWith('V-');

    if (finalLabelStartsWithC || finalLabelStartsWithV) {
      return {
        'isValid': false,
        'partNumber': null,
        'validationComment': 'Orden Incorrecto',
      };
    }

    // 5. Determinar el tipo de validación según la presencia de '/'
    final containerBase = containerCode.substring(2);
    final visualAidBase = visualAidCode.substring(2);

    // Ejecutar validaciones estructurales/combinacionales PRIMERO
    final structuralResult = _validateBasedOnCombinations(
      containerBase,
      visualAidBase,
      finalLabelCode,
    );

    // Si fallaron las validaciones estructurales, devolvemos ese resultado y
    // NO ejecutamos la validación de secuencia (que ahora es la última)
    if (!structuralResult['isValid']) {
      return structuralResult;
    }

    // Si las validaciones anteriores pasaron, ejecutamos la validación de secuencia (API)
    final sequenceValidation = await _validateFinalLabelSequence(
      finalLabelCode,
    );

    // Si la secuencia falla, devolvemos la info de secuencia (displayMessage, expectedOrder, validationComment)
    if (!sequenceValidation['isValid']) {
      return sequenceValidation;
    }

    // Si la secuencia pasa, devolvemos resultado combinado:
    // - isValid verdadero
    // - partNumber lo tomamos del resultado estructural (si existe)
    // - validationComment puede venir de sequenceValidation (normalmente null si ok)
    return {
      'isValid': true,
      'partNumber': structuralResult['partNumber'],
      'validationComment': sequenceValidation['validationComment'],
      'displayMessage': sequenceValidation['displayMessage'],
      'expectedOrder': sequenceValidation['expectedOrder'],
      'currentOrder': sequenceValidation['currentOrder'],
    };
  }

  /// Valida la secuencia de la etiqueta final mediante API
  /// Devuelve validationComment para BD y displayMessage para UI
  static Future<Map<String, dynamic>> _validateFinalLabelSequence(
    String finalLabelCode,
  ) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$_baseUrl/validate-sequence'),
        body: jsonEncode({'final_label_code': finalLabelCode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'isValid': data['isValid'] ?? false,
          'partNumber': null,
          'validationComment': data['validationComment'], // Para guardar en BD
          'displayMessage': data['displayMessage'] ?? data['validationComment'],
          'expectedOrder': data['expectedOrder'], // Orden esperada (opcional)
          'currentOrder': data['currentOrder'], // Orden actual (opcional)
        };
      } else {
        return {
          'isValid': false,
          'partNumber': null,
          'validationComment':
              'Error en la validación de secuencia: ${response.statusCode}',
          'displayMessage':
              'Error en la validación de secuencia: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'isValid': false,
        'partNumber': null,
        'validationComment': 'Error de conexión en la validación de secuencia',
        'displayMessage': 'Error de conexión en la validación de secuencia',
      };
    }
  }

  /// Determina el tipo de validación basado en las combinaciones de códigos
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

  /// Valida coincidencia directa cuando ambos códigos contienen '/'
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
        'validationComment': 'Mal Etiquetado',
      };
    }

    // Buscar el texto completo en la etiqueta final
    final containsPart = finalLabelCode.contains(containerBase);
    return {
      'isValid': containsPart,
      'partNumber': containsPart ? containerBase : null,
      'validationComment': containsPart ? null : 'Mal Etiquetado',
    };
  }

  /// Valida generando combinaciones cuando solo el contenedor tiene '/'
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
          'validationComment': containsPart ? null : 'Mal Etiquetado',
        };
      }
    }

    return {
      'isValid': false,
      'partNumber': null,
      'validationComment': 'Mal Etiquetado',
    };
  }

  /// Validación tradicional para códigos sin '/'
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
        'validationComment': 'Mal Etiquetado',
      };
    }

    // Verificar que el código base esté en la etiqueta final
    final containsPart = finalLabelCode.contains(containerBase.trim());
    return {
      'isValid': containsPart,
      'partNumber': containsPart ? containerBase : null,
      'validationComment': containsPart ? null : 'Mal Etiquetado',
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

  /// Envía los resultados de validación a la API con información del dispositivo
  static Future<List<String>?> sendValidationToAPI({
    required String containerCode,
    required String visualAidCode,
    required String finalLabelCode,
    required bool isValid,
    required String? partNumber,
    required String? validationComment,
  }) async {
    try {
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

      // Verificar permisos de ubicación
      final locationPermission = await Permission.location.isGranted;
      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();

      // Obtener IP y MAC (BSSID del router Wi-Fi)
      final networkInfo = NetworkInfo();
      String? ipAddress = await networkInfo.getWifiIP();
      String? macAddress =
          (locationPermission && isLocationEnabled)
              ? await networkInfo.getWifiBSSID()
              : null;

      // Preparar datos para enviar a la API
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

      // Enviar datos usando el interceptor HTTP
      final response = await HttpInterceptor.post(
        Uri.parse('$_baseUrl/material-validations'),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
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
      rethrow;
    }

    return null;
  }

  /// Obtiene el historial de validaciones desde la API
  static Future<List<Map<String, dynamic>>> getValidationHistory({
    int? workCenterId,
    String? status,
    int limit = 50,
  }) async {
    try {
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

      final response = await HttpInterceptor.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
          'Error al obtener el historial: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
