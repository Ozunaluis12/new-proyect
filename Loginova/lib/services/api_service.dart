import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio que gestiona la configuración de la API y el almacenamiento de sesión.
/// Proporciona métodos para manejar tokens y datos del usuario en SharedPreferences.
class ApiService {
  /// URL base del servidor API backend.
  static const String _apiBaseFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// URL base de la API a usar. Si se pasó `--dart-define=API_BASE_URL` se
  /// respeta eso (útil para apuntar a producción); si no, se elige según la
  /// plataforma: el emulador de Android no puede usar "localhost" para
  /// llegar al host (10.0.2.2 es la dirección especial que sí llega), y en
  /// web/desktop se usa 127.0.0.1 explícito para evitar que "localhost"
  /// resuelva a IPv6 (::1) cuando el backend solo escucha en IPv4.
  static String get baseUrl {
    if (_apiBaseFromEnv.isNotEmpty) {
      return _apiBaseFromEnv;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:5105/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // En emulador Android, localhost apunta al emulador, no al host.
      return 'http://10.0.2.2:5105/api';
    }

    // En desktop/Windows, localhost puede resolverse a IPv6 (::1),
    // mientras que el backend suele exponerse en IPv4 127.0.0.1.
    return 'http://127.0.0.1:5105/api';
  }

  static const String _tokenKey = 'loginova_token';
  static const String _usuarioKey = 'loginova_usuario';

  // El token JWT y los datos de sesión se guardan cifrados con las
  // primitivas seguras del sistema operativo (Keystore/Keychain/Credential
  // Manager) en vez de en preferencias planas, para que no queden legibles
  // por cualquiera con acceso al almacenamiento del dispositivo.
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Token JWT actual de la sesión.
  static String? token;

  /// Carga el token guardado desde el almacenamiento seguro.
  static Future<void> loadToken() async {
    token = await _secureStorage.read(key: _tokenKey);
  }

  /// Guarda el token y datos del usuario en el almacenamiento seguro.
  static Future<void> saveSession(String newToken, String usuarioJson) async {
    token = newToken;
    await _secureStorage.write(key: _tokenKey, value: newToken);
    await _secureStorage.write(key: _usuarioKey, value: usuarioJson);
  }

  /// Carga los datos del usuario guardados en el almacenamiento seguro.
  static Future<String?> loadUsuarioJson() async {
    return _secureStorage.read(key: _usuarioKey);
  }

  /// Limpia la sesión eliminando el token y datos del usuario.
  static Future<void> clearSession() async {
    token = null;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _usuarioKey);
  }

  /// Retorna los encabezados HTTP necesarios para las solicitudes a la API.
  static Map<String, String> get jsonHeaders {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
