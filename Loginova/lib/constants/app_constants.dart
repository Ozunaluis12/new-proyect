import 'package:flutter/foundation.dart';

/// Constantes globales de la aplicacion.
class AppConstants {
  /// Nombre de la aplicacion.
  static const String appName = 'Loginova';

  /// URL base del servidor API backend.
  static const String _apiBaseFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiUrl {
    if (_apiBaseFromEnv.isNotEmpty) {
      return _apiBaseFromEnv;
    }

    if (kIsWeb) {
      return 'http://localhost:5105/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5105/api';
    }

    return 'http://localhost:5105/api';
  }

  /// Google Maps API Key (CONFIGURAR AQUÍ)
  /// TODO: Reemplazar con tu propia API key de Google Cloud Console
  static const String googleMapsApiKey = 'TU_API_KEY_AQUI';

  /// Firebase Project ID (CONFIGURAR AQUÍ)
  /// TODO: Reemplazar con tu Project ID de Firebase
  static const String firebaseProjectId = 'loginova-proyecto';
}
