import 'package:shared_preferences/shared_preferences.dart';

/// Servicio que gestiona la configuración de la API y el almacenamiento de sesión.
/// Proporciona métodos para manejar tokens y datos del usuario en SharedPreferences.
class ApiService {
  /// URL base del servidor API backend.
  static const String baseUrl = 'http://localhost:5105/api';
  static const String _tokenKey = 'loginova_token';
  static const String _usuarioKey = 'loginova_usuario';

  /// Token JWT actual de la sesión.
  static String? token;

  /// Carga el token guardado desde las preferencias locales.
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
  }

  /// Guarda el token y datos del usuario en las preferencias locales.
  static Future<void> saveSession(String newToken, String usuarioJson) async {
    final prefs = await SharedPreferences.getInstance();
    token = newToken;
    await prefs.setString(_tokenKey, newToken);
    await prefs.setString(_usuarioKey, usuarioJson);
  }

  /// Carga los datos del usuario guardados en las preferencias locales.
  static Future<String?> loadUsuarioJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usuarioKey);
  }

  /// Limpia la sesión eliminando el token y datos del usuario.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    token = null;
    await prefs.remove(_tokenKey);
    await prefs.remove(_usuarioKey);
  }

  /// Retorna los encabezados HTTP necesarios para las solicitudes a la API.
  static Map<String, String> get jsonHeaders {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
