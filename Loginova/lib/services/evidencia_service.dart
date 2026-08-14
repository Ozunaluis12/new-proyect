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
    // Se anotan las evidencias que ya existían antes de subir la foto: si
    // más abajo hay que recuperarse de un error de red, esto es lo que
    // permite distinguir "ya se creó la evidencia nueva" de "no se creó
    // nada" (a diferencia del id o el comentario solos, que no alcanzan).
    Set<int> idsAntes = {};
    try {
      idsAntes = (await obtenerEvidenciasPorRecogida(evidencia.recogidaId))
          .map((e) => e.id)
          .toSet();
    } catch (_) {
      // No se pudo listar antes de guardar: si más abajo hace falta la
      // verificación de respaldo, simplemente no tendrá con qué comparar.
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/evidencias'),
    );

    request.fields['recogidaId'] = evidencia.recogidaId.toString();
    request.fields['comentario'] = evidencia.comentario ?? '';
    request.files.add(await http.MultipartFile.fromPath('foto', foto.path));

    final token = ApiService.token;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        throw Exception(
          'No se pudo guardar la evidencia (${response.statusCode}): ${response.body}',
        );
      }

      return Evidencia.fromJson(jsonDecode(response.body));
    } catch (_) {
      // La foto puede tardar varios segundos en subir en datos móviles: si
      // la conexión se cae justo después de que el servidor ya guardó la
      // evidencia, esto se ve como un error aunque sí se guardó. En vez de
      // reportar un fallo falso, se busca una evidencia nueva para esta
      // recogida antes de rendirse.
      final nueva = await _buscarEvidenciaNueva(
        evidencia.recogidaId,
        idsAntes,
      );
      if (nueva != null) return nueva;
      rethrow;
    }
  }

  /// Busca, entre las evidencias actuales de la recogida, alguna que no
  /// estuviera antes de intentar guardar (es decir, que sí se llegó a crear
  /// pese al error). Si hay más de una nueva (poco probable, pero posible si
  /// otro operador sube algo al mismo tiempo), se toma la de mayor id por
  /// ser la más reciente. Devuelve null si no se pudo confirmar.
  Future<Evidencia?> _buscarEvidenciaNueva(
    int recogidaId,
    Set<int> idsAntes,
  ) async {
    try {
      final actuales = await obtenerEvidenciasPorRecogida(recogidaId);
      final nuevas = actuales.where((e) => !idsAntes.contains(e.id)).toList()
        ..sort((a, b) => b.id.compareTo(a.id));
      return nuevas.isEmpty ? null : nuevas.first;
    } catch (_) {
      return null;
    }
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
