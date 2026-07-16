import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/cierre_caja.dart';
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

  /// Operadores/subadministradores que pueden tener caja, para el selector.
  Future<List<OperadorDisponible>> obtenerOperadoresDisponibles() async {
    final uri = Uri.parse('${ApiService.baseUrl}/ingresos/operadores');
    final response = await http.get(uri, headers: ApiService.jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los operadores');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => OperadorDisponible.fromJson(item)).toList();
  }

  /// Dinero pendiente por cerrar de un operador (con desglose y detalle).
  Future<ResumenCaja> resumenCaja(int operadorId) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/ingresos/resumen-caja',
    ).replace(queryParameters: {'operadorId': operadorId.toString()});

    final response = await http.get(uri, headers: ApiService.jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('Error al obtener el resumen de caja');
    }
    return ResumenCaja.fromJson(jsonDecode(response.body));
  }

  /// Cierra la caja de un operador: recoge todo lo pendiente en un nuevo cierre.
  Future<CierreCaja> cerrarCaja(int operadorId, {String? observaciones}) async {
    final uri = Uri.parse('${ApiService.baseUrl}/ingresos/cierre');
    final response = await http.post(
      uri,
      headers: ApiService.jsonHeaders,
      body: jsonEncode({
        'operadorId': operadorId,
        'observaciones': observaciones,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['mensaje'] ?? 'Error al cerrar caja');
    }
    return CierreCaja.fromJson(jsonDecode(response.body));
  }

  /// Historial de cierres de caja, con filtros opcionales.
  Future<List<CierreCaja>> obtenerHistorialCierres({
    int? operadorId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    final queryParameters = <String, String>{};
    if (operadorId != null) {
      queryParameters['operadorId'] = operadorId.toString();
    }
    if (fechaDesde != null) {
      queryParameters['fechaDesde'] = fechaDesde.toIso8601String();
    }
    if (fechaHasta != null) {
      queryParameters['fechaHasta'] = fechaHasta.toIso8601String();
    }

    final uri = Uri.parse('${ApiService.baseUrl}/ingresos/cierres').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await http.get(uri, headers: ApiService.jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el historial de cierres');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => CierreCaja.fromJson(item)).toList();
  }

  /// Detalle de un cierre puntual, incluyendo los ingresos que recogió.
  Future<CierreCaja> obtenerDetalleCierre(int id) async {
    final uri = Uri.parse('${ApiService.baseUrl}/ingresos/cierres/$id');
    final response = await http.get(uri, headers: ApiService.jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el detalle del cierre');
    }
    return CierreCaja.fromJson(jsonDecode(response.body));
  }
}
