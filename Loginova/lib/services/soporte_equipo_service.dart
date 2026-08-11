import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/usuario.dart';
import 'api_service.dart';

/// Administra las cuentas del propio equipo de Soporte (no las empresas
/// clientes). Permite que, si el equipo crece, cada persona tenga su
/// propio login en vez de compartir una sola cuenta.
class SoporteEquipoService {
  Future<List<Usuario>> obtenerCuentas() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/soporteusuarios'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las cuentas de Soporte');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Usuario.fromJson(item)).toList();
  }

  Future<void> crearCuenta({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/soporteusuarios'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo crear la cuenta de Soporte: ${response.body}');
    }
  }

  Future<void> eliminarCuenta(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/soporteusuarios/$id'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 204) {
      // Algunas respuestas de error (p. ej. 404 sin cuerpo) no traen JSON;
      // decodificar a ciegas ahí lanzaría FormatException en vez del
      // mensaje de error real.
      var mensaje = 'No se pudo eliminar la cuenta';
      if (response.body.isNotEmpty) {
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['mensaje'] is String) {
            mensaje = body['mensaje'] as String;
          }
        } catch (_) {
          // Cuerpo no era JSON válido: se mantiene el mensaje genérico.
        }
      }
      throw Exception(mensaje);
    }
  }
}
