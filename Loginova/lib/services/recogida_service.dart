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

    http.Response response;
    try {
      final streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    } catch (_) {
      // La foto puede tardar varios segundos en subir en datos móviles: si
      // la conexión se cae justo después de que el servidor ya procesó y
      // guardó el cambio, pero antes de que la respuesta llegue al
      // teléfono, esto se ve como un error de red aunque el guardado sí
      // ocurrió. En vez de reportar un fallo falso, se confirma el estado
      // real antes de rendirse.
      final actual = await _verificarSiQuedoGuardado(recogidaId, estado);
      if (actual != null) return actual;
      rethrow;
    }

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

  /// Confirma si el cambio de estado ya quedó aplicado del lado del
  /// servidor pese al error de red, para no dejar al operador con un falso
  /// "no se pudo guardar" cuando en realidad sí se guardó. Devuelve null si
  /// no se pudo confirmar (ahí sí se reporta el error tal cual).
  Future<Recogida?> _verificarSiQuedoGuardado(
    int recogidaId,
    String estadoEsperado,
  ) async {
    try {
      final actual = await obtenerRecogidaPorId(recogidaId);
      return actual.estado.toLowerCase() == estadoEsperado.toLowerCase()
          ? actual
          : null;
    } catch (_) {
      return null;
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
