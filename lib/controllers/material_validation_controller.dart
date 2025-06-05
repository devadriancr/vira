import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
      return {'isValid': false, 'partNumber': null};
    }

    // 2. Verificar formatos correctos (C- y V-)
    final containerValid =
        containerCode.startsWith('C-') && containerCode.length > 2;
    final visualAidValid =
        visualAidCode.startsWith('V-') && visualAidCode.length > 2;

    if (!containerValid || !visualAidValid) {
      return {'isValid': false, 'partNumber': null};
    }

    // 3. Extraer códigos base
    final containerBase = containerCode.substring(2);
    final visualAidBase = visualAidCode.substring(2);

    // 4. Verificar coincidencia de códigos base
    if (containerBase != visualAidBase) {
      return {'isValid': false, 'partNumber': null};
    }

    // 5. Verificar que el código base esté en la etiqueta final
    final containsPart = finalLabelCode.contains(containerBase);
    return {
      'isValid': containsPart,
      'partNumber': containsPart ? containerBase : null,
    };
  }

  static Future<void> sendValidationToAPI({
    required String containerCode,
    required String visualAidCode,
    required String finalLabelCode,
    required bool isValid,
    required int workCenterId,
    required String? partNumber,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/material-validations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'work_center_id': workCenterId,
          'container_code': containerCode,
          'visual_aid_code': visualAidCode,
          'final_label_code': finalLabelCode,
          'validation_status': isValid ? 'OK' : 'NG',
          'part_number': partNumber,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('Validación enviada exitosamente: ${data['message']}');
      } else if (response.statusCode == 422) {
        final error = jsonDecode(response.body);
        throw Exception('Error de validación: ${error['message']}');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes acceso a este centro de trabajo');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error enviando validación a la API: $e');
      rethrow;
    }
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
        queryParams['status'] = status;
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

  static Future<Map<String, dynamic>> getValidationStatistics({
    int? workCenterId,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final queryParams = <String, String>{};

      if (workCenterId != null) {
        queryParams['work_center_id'] = workCenterId.toString();
      }

      final uri = Uri.parse(
        '$_baseUrl/material-validations/statistics',
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
        return data['data'];
      } else {
        throw Exception(
          'Error al obtener estadísticas: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      rethrow;
    }
  }
}
