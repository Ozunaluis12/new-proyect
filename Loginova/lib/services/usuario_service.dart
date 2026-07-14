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

  /// Crea un usuario nuevo con rol y permisos asignados.
  Future<Usuario> crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
    required List<String> permisos,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/usuarios'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'password': password,
        'rol': rol,
        'permisos': permisos,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo crear el usuario');
    }

    return Usuario.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Actualiza un usuario existente con rol y permisos.
  Future<void> actualizarUsuario({
    required int id,
    required String nombre,
    required String correo,
    String? password,
    required String rol,
    required List<String> permisos,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/usuarios/$id'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'password': password,
        'rol': rol,
        'permisos': permisos,
      }),
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudo actualizar el usuario');
    }
  }

  /// Elimina un usuario del servidor por su identificador.
  Future<void> eliminarUsuario(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/usuarios/$id'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudo eliminar el usuario');
    }
  }
}
