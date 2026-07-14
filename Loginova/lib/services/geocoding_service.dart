import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/app_logger.dart';
import 'location_service.dart';

/// Servicio especializado para geocodificación y reverse geocodificación.
/// Usa Nominatim (OpenStreetMap) como respaldo robusto para desktop y móvil.
class GeocodingService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org';

  static Uri buildSearchUri(String query, {int limit = 4}) {
    return Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'format': 'jsonv2',
        'limit': limit.toString(),
        'q': query,
        'addressdetails': '1',
        'accept-language': 'es',
      },
    );
  }

  static Uri buildReverseGeocodeUri(double latitude, double longitude) {
    return Uri.parse('$_baseUrl/reverse').replace(
      queryParameters: {
        'format': 'jsonv2',
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'accept-language': 'es',
      },
    );
  }

  /// Convierte una dirección de texto a coordenadas (Geocodificación Directa).
  static Future<LocationData?> geocodeAddress(String address) async {
    try {
      if (address.isEmpty) return null;

      final uri = buildSearchUri(address, limit: 3);

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json', 'User-Agent': 'Loginova/1.0'},
      );

      if (response.statusCode != 200) {
        AppLogger.warn('Geocodificación fallida: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      if (data.isEmpty) {
        AppLogger.debug('No se encontraron coordenadas para: $address');
        return null;
      }

      final first = data.first as Map<String, dynamic>;
      return parseNominatimLocation(first);
    } catch (e) {
      AppLogger.warn('Error en geocodificación: $e', error: e);
      return null;
    }
  }

  /// Convierte coordenadas a dirección legible (Reverse Geocodificación).
  static Future<String?> reverseGeocode(
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

  /// Obtiene múltiples direcciones candidatas para una búsqueda.
  static Future<List<String>> searchAddresses(String query) async {
    try {
      if (query.isEmpty) return [];

      final uri = buildSearchUri(query, limit: 4);

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json', 'User-Agent': 'Loginova/1.0'},
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => formatNominatimAddress(item as Map<String, dynamic>))
          .where((value) => value.isNotEmpty)
          .toList();
    } catch (e) {
      AppLogger.warn('Error en búsqueda de direcciones: $e', error: e);
      return [];
    }
  }

  /// Valida si una dirección es válida y retorna sus coordenadas.
  static Future<bool> validateAddress(String address) async {
    final location = await geocodeAddress(address);
    return location != null;
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
