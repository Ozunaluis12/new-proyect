import 'dart:convert';
import 'dart:io';

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
  Future<Evidencia> guardarEvidencia(
    Evidencia evidencia, {
    required File foto,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/evidencias'),
    );

    request.fields['recogidaId'] = evidencia.recogidaId.toString();
    request.fields['comentario'] = evidencia.comentario;
    request.files.add(await http.MultipartFile.fromPath('foto', foto.path));

    final token = ApiService.token;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception(
        'No se pudo guardar la evidencia (${response.statusCode}): ${response.body}',
      );
    }

    return Evidencia.fromJson(jsonDecode(response.body));
  }

  /// Obtiene las evidencias asociadas a una recogida.
  Future<List<Evidencia>> obtenerEvidenciasPorRecogida(int recogidaId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/evidencias/recogida/$recogidaId'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las evidencias de la recogida');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Evidencia.fromJson(item)).toList();
  }

  /// Elimina una evidencia del servidor por su identificador.
  Future<void> eliminarEvidencia(int evidenciaId) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/evidencias/$evidenciaId'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudo eliminar la evidencia');
    }
  }
}
