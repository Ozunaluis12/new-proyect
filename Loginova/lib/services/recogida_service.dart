import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/recogida.dart';
import 'api_service.dart';

/// Servicio que gestiona la comunicación con el backend para operaciones CRUD de recogidas.
class RecogidaService {
  /// Obtiene todas las recogidas del servidor.
  Future<List<Recogida>> obtenerRecogidas() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/recogidas'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las recogidas');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Recogida.fromJson(item)).toList();
  }

  /// Crea una nueva recogida en el servidor y retorna la recogida creada con ID.
  Future<Recogida> crearRecogida(Recogida recogida) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/recogidas'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode(recogida.toRequestJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo crear la recogida');
    }

    return Recogida.fromJson(jsonDecode(response.body));
  }

  /// Actualiza una recogida existente en el servidor.
  Future<void> actualizarRecogida(Recogida recogida) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/recogidas/${recogida.id}'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode(recogida.toRequestJson()),
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudo actualizar la recogida');
    }
  }

  /// Actualiza solo el estado de una recogida y registra evidencia asociada.
  Future<Recogida> actualizarEstadoRecogida(
    int recogidaId, {
    required String estado,
    File? foto,
    required bool dineroRecibido,
    double? montoCobrado,
    String? formaPago,
    String? comentario,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiService.baseUrl}/recogidas/$recogidaId/estado'),
    );

    request.fields['estado'] = estado;
    request.fields['dineroRecibido'] = dineroRecibido.toString();
    if (montoCobrado != null) {
      request.fields['montoCobrado'] = montoCobrado.toString();
    }
    if (formaPago != null) {
      request.fields['formaPago'] = formaPago;
    }
    if ((comentario ?? '').isNotEmpty) {
      request.fields['comentario'] = comentario!;
    }
    if (foto != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
    }

    final token = ApiService.token;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('No se pudo actualizar el estado de la recogida');
    }

    return Recogida.fromJson(jsonDecode(response.body));
  }

  /// Elimina una recogida del servidor por su identificador.
  Future<void> eliminarRecogida(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/recogidas/$id'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudo eliminar la recogida');
    }
  }
}
