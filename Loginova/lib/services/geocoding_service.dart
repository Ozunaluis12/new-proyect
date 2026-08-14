import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/app_logger.dart';
import 'location_service.dart';

/// Una dirección sugerida por el buscador, con sus coordenadas ya resueltas
/// (para no tener que volver a geocodificar cuando el usuario la selecciona).
class AddressSuggestion {
  final String label;
  final double latitude;
  final double longitude;
  final String? city;

  AddressSuggestion({
    required this.label,
    required this.latitude,
    required this.longitude,
    this.city,
  });
}

/// Servicio especializado para geocodificación y reverse geocodificación.
///
/// Usa Mapbox cuando hay un access token configurado (mejor cobertura de
/// direcciones exactas en Colombia, con autocompletado tipo Google Maps).
/// Si no hay token, cae a Nominatim (OpenStreetMap): sigue funcionando sin
/// configuración adicional, pero con menos precisión a nivel de predio.
class GeocodingService {
  static const _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const _mapboxBaseUrl =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';

  static const String _mapboxToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );

  static bool get usaMapbox => _mapboxToken.isNotEmpty;

  // Medio grado de latitud/longitud equivale a ~55km en el ecuador: suficiente
  // para cubrir una ciudad y sus alrededores sin restringir de más.
  static const double _nearbyBoxDegrees = 0.5;

  // Ciudad de operación de la empresa del usuario logueado (ver Empresa en
  // el backend), usada como sesgo por defecto cuando aún no se conoce su
  // ubicación GPS real. No hay una ciudad fija en el código: quien inicia la
  // sesión la fija llamando a [configurarUbicacionPorDefecto] con lo que
  // devuelve `/miempresa`. Si nunca se configura (empresa sin ciudad
  // definida, o antes de que cargue esa respuesta), la búsqueda sigue
  // funcionando, solo sin sesgo de ciudad — restringida únicamente a
  // Colombia por `countrycodes`.
  static double? _defaultLatitude;
  static double? _defaultLongitude;

  /// Fija la ubicación que se usa como sesgo por defecto cuando todavía no
  /// se conoce el GPS real del operador. Se llama una vez al iniciar sesión
  /// (o al restaurar la sesión guardada) con la ciudad de operación de la
  /// empresa del usuario logueado.
  static void configurarUbicacionPorDefecto(double? latitud, double? longitud) {
    _defaultLatitude = latitud;
    _defaultLongitude = longitud;
  }

  /// Ciudad de operación configurada (ver [configurarUbicacionPorDefecto]),
  /// para que las pantallas de mapa puedan centrarse ahí como alternativa al
  /// GPS real, en vez de una ciudad fija en el código.
  static double? get ubicacionPorDefectoLatitud => _defaultLatitude;
  static double? get ubicacionPorDefectoLongitud => _defaultLongitude;

  // La política de uso de Nominatim exige un User-Agent con datos de
  // contacto real; sin eso pueden bloquear la IP si hay tráfico sostenido.
  static const Map<String, String> _nominatimHeaders = {
    'Accept': 'application/json',
    'User-Agent': 'Loginova/1.0 (ozunaluis872@gmail.com)',
  };

  /// Obtiene múltiples direcciones candidatas para una búsqueda, con sus
  /// coordenadas ya resueltas.
  static Future<List<AddressSuggestion>> searchAddresses(
    String query, {
    double? nearLatitude,
    double? nearLongitude,
  }) async {
    if (query.isEmpty) return [];

    return usaMapbox
        ? _searchMapbox(
            query,
            limit: 5,
            nearLatitude: nearLatitude,
            nearLongitude: nearLongitude,
          )
        : _searchNominatim(
            query,
            limit: 4,
            nearLatitude: nearLatitude,
            nearLongitude: nearLongitude,
          );
  }

  /// Convierte una dirección de texto a coordenadas (Geocodificación Directa).
  static Future<LocationData?> geocodeAddress(
    String address, {
    double? nearLatitude,
    double? nearLongitude,
  }) async {
    if (address.isEmpty) return null;

    final resultados = await searchAddresses(
      address,
      nearLatitude: nearLatitude,
      nearLongitude: nearLongitude,
    );
    if (resultados.isEmpty) return null;

    final primero = resultados.first;
    return LocationData(
      latitude: primero.latitude,
      longitude: primero.longitude,
      accuracy: 0,
      timestamp: DateTime.now(),
    );
  }

  /// Convierte coordenadas a dirección legible (Reverse Geocodificación).
  static Future<String?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    return usaMapbox
        ? _reverseMapbox(latitude, longitude)
        : _reverseNominatim(latitude, longitude);
  }

  /// Valida si una dirección es válida y retorna sus coordenadas.
  static Future<bool> validateAddress(String address) async {
    final location = await geocodeAddress(address);
    return location != null;
  }

  // ---------------------------------------------------------------------
  // Mapbox
  // ---------------------------------------------------------------------

  static Future<List<AddressSuggestion>> _searchMapbox(
    String query, {
    required int limit,
    double? nearLatitude,
    double? nearLongitude,
  }) async {
    try {
      final params = <String, String>{
        'access_token': _mapboxToken,
        'autocomplete': 'true',
        'language': 'es',
        'country': 'co',
        'limit': limit.toString(),
      };

      final proximityLat = nearLatitude ?? _defaultLatitude;
      final proximityLon = nearLongitude ?? _defaultLongitude;
      if (proximityLat != null && proximityLon != null) {
        params['proximity'] = '$proximityLon,$proximityLat';
      }

      final uri = Uri.parse(
        '$_mapboxBaseUrl/${Uri.encodeComponent(query)}.json',
      ).replace(queryParameters: params);

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        AppLogger.warn('Mapbox geocoding falló: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];

      return features
          .map((item) => _mapboxFeatureToSuggestion(item as Map<String, dynamic>))
          .whereType<AddressSuggestion>()
          .toList();
    } catch (e) {
      AppLogger.warn('Error en búsqueda Mapbox: $e', error: e);
      return [];
    }
  }

  static Future<String?> _reverseMapbox(double latitude, double longitude) async {
    try {
      final uri = Uri.parse(
        '$_mapboxBaseUrl/$longitude,$latitude.json',
      ).replace(
        queryParameters: {'access_token': _mapboxToken, 'language': 'es'},
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        AppLogger.warn(
          'Mapbox reverse geocoding falló: ${response.statusCode}',
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];
      if (features.isEmpty) return null;

      return (features.first as Map<String, dynamic>)['place_name']
          ?.toString();
    } catch (e) {
      AppLogger.warn('Error en reverse geocoding Mapbox: $e', error: e);
      return null;
    }
  }

  static AddressSuggestion? _mapboxFeatureToSuggestion(
    Map<String, dynamic> feature,
  ) {
    final placeName = feature['place_name']?.toString();
    final center = feature['center'] as List<dynamic>?;
    if (placeName == null || center == null || center.length != 2) {
      return null;
    }

    final lon = (center[0] as num).toDouble();
    final lat = (center[1] as num).toDouble();
    return AddressSuggestion(
      label: placeName,
      latitude: lat,
      longitude: lon,
      city: _mapboxCiudad(feature),
    );
  }

  /// Extrae la ciudad del contexto jerárquico que devuelve Mapbox (el
  /// elemento cuyo id empieza con "place.", su convención para ciudad).
  static String? _mapboxCiudad(Map<String, dynamic> feature) {
    final context = feature['context'] as List<dynamic>?;
    if (context == null) return null;

    for (final item in context) {
      final map = item as Map<String, dynamic>;
      final id = map['id']?.toString() ?? '';
      if (id.startsWith('place.')) {
        return map['text_es']?.toString() ?? map['text']?.toString();
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Nominatim (respaldo gratis sin configuración)
  // ---------------------------------------------------------------------

  static Uri buildSearchUri(
    String query, {
    int limit = 4,
    double? nearLatitude,
    double? nearLongitude,
    bool bounded = false,
  }) {
    final params = <String, String>{
      'format': 'jsonv2',
      'limit': limit.toString(),
      'q': query,
      'addressdetails': '1',
      'accept-language': 'es',
      // Restringe siempre a Colombia: evita que una dirección genérica (ej.
      // "Calle 10 # 5-20") traiga como primer resultado una coincidencia en
      // otro país.
      'countrycodes': 'co',
    };

    // Cuando se pide una búsqueda acotada ("bounded") y no se conoce todavía
    // la ubicación GPS real del usuario, se usa la ciudad de operación de su
    // empresa (ver [configurarUbicacionPorDefecto]) como centro por defecto.
    // Si tampoco hay eso configurado, no hay caja: la búsqueda queda
    // restringida solo a Colombia.
    final lat = nearLatitude ?? (bounded ? _defaultLatitude : null);
    final lon = nearLongitude ?? (bounded ? _defaultLongitude : null);

    if (lat != null && lon != null) {
      final minLon = lon - _nearbyBoxDegrees;
      final maxLon = lon + _nearbyBoxDegrees;
      final minLat = lat - _nearbyBoxDegrees;
      final maxLat = lat + _nearbyBoxDegrees;
      params['viewbox'] = '$minLon,$maxLat,$maxLon,$minLat';
      if (bounded) {
        // A diferencia del viewbox suelto (solo un sesgo), esto vuelve la
        // caja una restricción dura: Nominatim no devuelve nada fuera de
        // ella. Es lo que hacía que, aunque hubiera sesgo, direcciones de
        // otras ciudades igual ganaran por tener mejor puntaje interno.
        params['bounded'] = '1';
      }
    }

    return Uri.parse(
      '$_nominatimBaseUrl/search',
    ).replace(queryParameters: params);
  }

  static Uri buildReverseGeocodeUri(double latitude, double longitude) {
    return Uri.parse('$_nominatimBaseUrl/reverse').replace(
      queryParameters: {
        'format': 'jsonv2',
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'accept-language': 'es',
      },
    );
  }

  static Future<List<AddressSuggestion>> _searchNominatim(
    String query, {
    required int limit,
    double? nearLatitude,
    double? nearLongitude,
  }) async {
    try {
      // Primero se busca acotado a la zona del usuario (o Bucaramanga si aún
      // no se conoce su ubicación real). Solo si eso no encuentra nada se
      // repite sin la restricción dura, para no perder direcciones legítimas
      // que estén lejos (p. ej. una recogida fuera de la ciudad habitual).
      final resultadosCercanos = await _fetchNominatim(
        buildSearchUri(
          query,
          limit: limit,
          nearLatitude: nearLatitude,
          nearLongitude: nearLongitude,
          bounded: true,
        ),
      );
      if (resultadosCercanos.isNotEmpty) return resultadosCercanos;

      return await _fetchNominatim(
        buildSearchUri(
          query,
          limit: limit,
          nearLatitude: nearLatitude,
          nearLongitude: nearLongitude,
        ),
      );
    } catch (e) {
      AppLogger.warn('Error en búsqueda de direcciones: $e', error: e);
      return [];
    }
  }

  static Future<List<AddressSuggestion>> _fetchNominatim(Uri uri) async {
    final response = await http.get(
      uri,
      headers: _nominatimHeaders,
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => _nominatimResultToSuggestion(item as Map<String, dynamic>))
        .whereType<AddressSuggestion>()
        .toList();
  }

  static Future<String?> _reverseNominatim(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = buildReverseGeocodeUri(latitude, longitude);

      final response = await http.get(
        uri,
        headers: _nominatimHeaders,
      );

      if (response.statusCode != 200) {
        AppLogger.warn(
          'Reverse geocodificación fallida: ${response.statusCode}',
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return formatNominatimAddress(data);
    } catch (e) {
      AppLogger.warn('Error en reverse geocodificación: $e', error: e);
      return null;
    }
  }

  static AddressSuggestion? _nominatimResultToSuggestion(
    Map<String, dynamic> result,
  ) {
    final location = parseNominatimLocation(result);
    if (location == null) return null;

    final label = formatNominatimAddress(result);
    if (label.isEmpty) return null;

    String? ciudad;
    final address = result['address'];
    if (address is Map<String, dynamic>) {
      ciudad =
          address['city']?.toString() ??
          address['town']?.toString() ??
          address['municipality']?.toString();
    }

    return AddressSuggestion(
      label: label,
      latitude: location.latitude,
      longitude: location.longitude,
      city: ciudad,
    );
  }

  static String formatNominatimAddress(Map<String, dynamic> result) {
    final displayName = result['display_name']?.toString() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }

    final address = result['address'];
    if (address is Map<String, dynamic>) {
      final parts = <String>[];
      final road = address['road']?.toString();
      final suburb = address['suburb']?.toString();
      final city = address['city']?.toString() ?? address['town']?.toString();
      final state = address['state']?.toString();
      final country = address['country']?.toString();

      if (road != null && road.isNotEmpty) parts.add(road);
      if (suburb != null && suburb.isNotEmpty) parts.add(suburb);
      if (city != null && city.isNotEmpty) parts.add(city);
      if (state != null && state.isNotEmpty) parts.add(state);
      if (country != null && country.isNotEmpty) parts.add(country);
      return parts.join(', ');
    }

    return '';
  }

  static LocationData? parseNominatimLocation(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat']?.toString() ?? '');
    final lon = double.tryParse(result['lon']?.toString() ?? '');

    if (lat == null || lon == null) {
      return null;
    }

    return LocationData(
      latitude: lat,
      longitude: lon,
      accuracy: 0,
      timestamp: DateTime.now(),
    );
  }
}
