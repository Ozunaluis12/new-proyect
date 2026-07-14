import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/ingreso.dart';
import 'api_service.dart';

class IngresoService {
  Future<List<Ingreso>> obtenerIngresos({
    String? cliente,
    String? operador,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    final queryParameters = <String, String>{};

    if (cliente != null && cliente.trim().isNotEmpty) {
      queryParameters['cliente'] = cliente.trim();
    }
    if (operador != null && operador.trim().isNotEmpty) {
      queryParameters['operador'] = operador.trim();
    }
    if (fechaDesde != null) {
      queryParameters['fechaDesde'] = fechaDesde.toIso8601String();
    }
    if (fechaHasta != null) {
      queryParameters['fechaHasta'] = fechaHasta.toIso8601String();
    }

    final uri = Uri.parse('${ApiService.baseUrl}/ingresos').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await http.get(uri, headers: ApiService.jsonHeaders);

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los ingresos');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Ingreso.fromJson(item)).toList();
  }

  Future<Uint8List> exportarIngresosCsv({
    String? cliente,
    String? operador,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    final queryParameters = <String, String>{};

    if (cliente != null && cliente.trim().isNotEmpty) {
      queryParameters['cliente'] = cliente.trim();
    }
    if (operador != null && operador.trim().isNotEmpty) {
      queryParameters['operador'] = operador.trim();
    }
    if (fechaDesde != null) {
      queryParameters['fechaDesde'] = fechaDesde.toIso8601String();
    }
    if (fechaHasta != null) {
      queryParameters['fechaHasta'] = fechaHasta.toIso8601String();
    }

    final uri = Uri.parse('${ApiService.baseUrl}/ingresos/export').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await http.get(uri, headers: ApiService.jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('Error al exportar ingresos');
    }

    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> resumenCaja(
    int operadorId,
    DateTime fecha,
  ) async {
    final uri = Uri.parse('${ApiService.baseUrl}/ingresos/resumen-caja')
        .replace(
          queryParameters: {
            'operadorId': operadorId.toString(),
            'fecha': fecha.toIso8601String(),
          },
        );

    final response = await http.get(uri, headers: ApiService.jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('Error al obtener resumen de caja');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> cerrarCaja(
    int operadorId,
    DateTime fecha, {
    String? observaciones,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/ingresos/cierre');
    final body = jsonEncode({
      'OperadorId': operadorId,
      'Fecha': fecha.toIso8601String(),
      'Observaciones': observaciones ?? '',
    });

    final response = await http.post(
      uri,
      headers: ApiService.jsonHeaders,
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('Error al cerrar caja');
    }
  }
}
