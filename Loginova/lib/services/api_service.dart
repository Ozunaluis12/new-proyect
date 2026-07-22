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

  static const String _serverUrlOverrideKey = 'loginova_server_url_override';

  // Permite que un mismo APK compilado sirva a distintos clientes: cada
  // instalación puede apuntar su propio backend desde la app (pantalla de
  // "Configurar servidor" en el login), sin depender de recompilar con un
  // --dart-define distinto para cada empresa. Se guarda en el dispositivo
  // y tiene prioridad sobre el valor de compilación.
  static String? _serverUrlOverride;

  /// Carga la URL de servidor guardada (si el usuario configuró una) al
  /// iniciar la app. Debe llamarse antes de que cualquier pantalla use
  /// [baseUrl].
  static Future<void> loadServerUrlOverride() async {
    final saved = await _secureStorage.read(key: _serverUrlOverrideKey);
    _serverUrlOverride = (saved == null || saved.trim().isEmpty)
        ? null
        : saved.trim();
  }

  /// Configura (o limpia, pasando null) la URL de servidor que va a usar
  /// esta instalación de la app a partir de ahora.
  static Future<void> setServerUrlOverride(String? url) async {
    final normalizado = (url == null || url.trim().isEmpty)
        ? null
        : url.trim().replaceAll(RegExp(r'/+$'), '');

    _serverUrlOverride = normalizado;

    if (normalizado == null) {
      await _secureStorage.delete(key: _serverUrlOverrideKey);
    } else {
      await _secureStorage.write(
        key: _serverUrlOverrideKey,
        value: normalizado,
      );
    }
  }

  /// URL de servidor configurada manualmente en este dispositivo, o null si
  /// esta instalación usa el valor de compilación/por defecto.
  static String? get serverUrlOverride => _serverUrlOverride;

  /// URL base de la API a usar. Prioridad: 1) la configurada manualmente en
  /// el dispositivo (ver [setServerUrlOverride]), 2) `--dart-define=API_BASE_URL`
  /// (útil para apuntar a producción al compilar), 3) un valor por defecto
  /// según la plataforma: el emulador de Android no puede usar "localhost"
  /// para llegar al host (10.0.2.2 es la dirección especial que sí llega), y
  /// en web/desktop se usa 127.0.0.1 explícito para evitar que "localhost"
  /// resuelva a IPv6 (::1) cuando el backend solo escucha en IPv4.
  static String get baseUrl {
    if (_serverUrlOverride != null && _serverUrlOverride!.isNotEmpty) {
      return _serverUrlOverride!;
    }

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
