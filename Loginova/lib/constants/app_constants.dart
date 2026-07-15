/// Constantes globales de la aplicacion.
class AppConstants {
  /// Nombre de la aplicacion.
  static const String appName = 'Loginova';

  /// API key de Google Maps para las llamadas a Directions/Distance Matrix.
  ///
  /// Para desarrollo local puedes pasarla con:
  /// flutter run --dart-define=GOOGLE_MAPS_API_KEY=TU_API_KEY
  ///
  /// En Flutter Web el mapa visual se carga desde web/index.html.
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasGoogleMapsApiKey => googleMapsApiKey.trim().isNotEmpty;

  /// Firebase Project ID (CONFIGURAR AQUÍ)
  /// TODO: Reemplazar con tu Project ID de Firebase
  static const String firebaseProjectId = 'loginova-proyecto';
}
