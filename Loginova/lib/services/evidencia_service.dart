import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/evidencia.dart';
import 'api_service.dart';

/// Servicio que gestiona la comunicación con el backend para operaciones CRUD de evidencias.
class EvidenciaService {
  /// Obtiene la lista completa de evidencias del servidor.
  Future<List<Evidencia>> obtenerEvidencias() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/evidencias'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las evidencias');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Evidencia.fromJson(item)).toList();
  }

  /// Guarda una nueva evidencia (foto) en el servidor.
  Future<Evidencia> guardarEvidencia(Evidencia evidencia) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/evidencias'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode(evidencia.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo guardar la evidencia');
    }

    return Evidencia.fromJson(jsonDecode(response.body));
  }
}
