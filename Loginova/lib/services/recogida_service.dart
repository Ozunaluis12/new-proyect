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

  /// Obtiene una recogida puntual por su identificador.
  Future<Recogida> obtenerRecogidaPorId(int id) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/recogidas/$id'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar la recogida');
    }

    return Recogida.fromJson(jsonDecode(response.body));
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
    int? cantidadPaquetes,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiService.baseUrl}/recogidas/$recogidaId/estado'),
    );

    request.fields['estado'] = estado;
    request.fields['dineroRecibido'] = dineroRecibido.toString();
    if (cantidadPaquetes != null) {
      request.fields['cantidadPaquetes'] = cantidadPaquetes.toString();
    }
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

    // El servidor ya guardó el cambio (200 OK). Si por cualquier motivo no
    // podemos interpretar el cuerpo de la respuesta, no reportamos un error
    // falso: volvemos a pedir la recogida ya actualizada.
    try {
      return Recogida.fromJson(jsonDecode(response.body));
    } catch (_) {
      return obtenerRecogidaPorId(recogidaId);
    }
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
