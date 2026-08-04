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

/// Servicio que gestiona las peticiones de autenticación al backend: login
/// y el flujo de dos pasos de recuperación de contraseña (solicitar código
/// por correo y luego resetear con ese código). No hay registro público:
/// toda cuenta nueva la crea un Administrador o Soporte.
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

  /// Solicita el código de recuperación de contraseña por correo.
  /// Siempre responde 200 (exista o no el correo), para no revelar qué
  /// correos están registrados.
  Future<bool> forgotPassword(String correo) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/forgot-password'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({'correo': correo}),
    );

    return response.statusCode == 200;
  }

  /// Verifica el código recibido por correo y establece la nueva contraseña.
  Future<bool> resetPassword(
    String correo,
    String codigo,
    String nuevaPassword,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/reset-password'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({
        'correo': correo,
        'token': codigo,
        'nuevaPassword': nuevaPassword,
      }),
    );

    return response.statusCode == 204;
  }
}
