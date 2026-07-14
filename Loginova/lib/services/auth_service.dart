import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/usuario.dart';
import 'api_service.dart';

/// Resultado de autenticación que incluye el token y el usuario autenticado.
class AuthResult {
  final String token;
  final Usuario usuario;

  AuthResult({required this.token, required this.usuario});
}

class AuthService {
  /// Envía la solicitud de inicio de sesión al backend y guarda la sesión si es exitosa.
  Future<AuthResult?> login(String correo, String password) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/login'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({'correo': correo, 'password': password}),
    );

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final usuario = Usuario.fromJson(data['usuario']);

    await ApiService.saveSession(token, jsonEncode(usuario.toJson()));

    return AuthResult(token: token, usuario: usuario);
  }

  /// Registra un usuario nuevo en el backend y guarda la sesión al recibir el token.
  Future<AuthResult?> register(
    String nombre,
    String correo,
    String password, {
    String rol = 'Cliente',
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/register'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'password': password,
        'rol': rol,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final usuario = Usuario.fromJson(data['usuario']);

    await ApiService.saveSession(token, jsonEncode(usuario.toJson()));
    return AuthResult(token: token, usuario: usuario);
  }

  /// Solicita el restablecimiento de contraseña en el backend.
  Future<bool> forgotPassword(String correo, String password) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/forgot-password'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({'correo': correo, 'password': password}),
    );

    return response.statusCode == 204;
  }
}
