import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/usuario.dart';
import 'api_service.dart';

/// Servicio que gestiona la carga de usuarios desde el backend.
class UsuarioService {
  /// Obtiene la lista completa de usuarios.
  Future<List<Usuario>> obtenerUsuarios() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/usuarios'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los usuarios');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Usuario.fromJson(item)).toList();
  }
}
