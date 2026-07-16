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

  AddressSuggestion({
    required this.label,
    required this.latitude,
    required this.longitude,
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

      if (nearLatitude != null && nearLongitude != null) {
        params['proximity'] = '$nearLongitude,$nearLatitude';
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
    return AddressSuggestion(label: placeName, latitude: lat, longitude: lon);
  }

  // ---------------------------------------------------------------------
  // Nominatim (respaldo gratis sin configuración)
  // ---------------------------------------------------------------------

  static Uri buildSearchUri(
    String query, {
    int limit = 4,
    double? nearLatitude,
    double? nearLongitude,
  }) {
    final params = <String, String>{
      'format': 'jsonv2',
      'limit': limit.toString(),
      'q': query,
      'addressdetails': '1',
      'accept-language': 'es',
    };

    if (nearLatitude != null && nearLongitude != null) {
      // Sesga los resultados hacia la zona donde está el usuario, para que una
      // dirección genérica (ej. "Calle 10 # 5-20") no traiga coincidencias en
      // otro país. No es una restricción dura: si no hay nada cerca, Nominatim
      // igual puede devolver resultados fuera de la caja.
      final minLon = nearLongitude - _nearbyBoxDegrees;
      final maxLon = nearLongitude + _nearbyBoxDegrees;
      final minLat = nearLatitude - _nearbyBoxDegrees;
      final maxLat = nearLatitude + _nearbyBoxDegrees;
      params['viewbox'] = '$minLon,$maxLat,$maxLon,$minLat';
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
      final uri = buildSearchUri(
        query,
        limit: limit,
        nearLatitude: nearLatitude,
        nearLongitude: nearLongitude,
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json', 'User-Agent': 'Loginova/1.0'},
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => _nominatimResultToSuggestion(item as Map<String, dynamic>))
          .whereType<AddressSuggestion>()
          .toList();
    } catch (e) {
      AppLogger.warn('Error en búsqueda de direcciones: $e', error: e);
      return [];
    }
  }

  static Future<String?> _reverseNominatim(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = buildReverseGeocodeUri(latitude, longitude);

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json', 'User-Agent': 'Loginova/1.0'},
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

    return AddressSuggestion(
      label: label,
      latitude: location.latitude,
      longitude: location.longitude,
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
