import 'package:geocoding/geocoding.dart' as geocoding;
import 'location_service.dart';

/// Servicio especializado para geocodificación y reverse geocodificación.
/// Convierte direcciones a coordenadas y viceversa.
class GeocodingService {
  /// Convierte una dirección de texto a coordenadas (Geocodificación Directa).
  /// 
  /// Ejemplo: "Calle 10 123, Medellín" → (6.2442, -75.5812)
  static Future<LocationData?> geocodeAddress(String address) async {
    try {
      if (address.isEmpty) return null;

      final locations = await geocoding.locationFromAddress(address);

      if (locations.isEmpty) {
        print('No se encontraron coordenadas para: $address');
        return null;
      }

      final location = locations.first;
      return LocationData(
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: 0,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error en geocodificación: $e');
      return null;
    }
  }

  /// Convierte coordenadas a dirección legible (Reverse Geocodificación).
  /// 
  /// Ejemplo: (6.2442, -75.5812) → "Calle 10, Medellín, Antioquia"
  static Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks =
          await geocoding.placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        print('No se encontró dirección para: $latitude, $longitude');
        return null;
      }

      final placemark = placemarks.first;
      return _formatAddress(placemark);
    } catch (e) {
      print('Error en reverse geocodificación: $e');
      return null;
    }
  }

  /// Formatea un placemark en una dirección legible.
  static String _formatAddress(geocoding.Placemark placemark) {
    final parts = <String>[];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }

    if (placemark.subThoroughfare != null &&
        placemark.subThoroughfare!.isNotEmpty) {
      parts.add('#${placemark.subThoroughfare}');
    }

    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }

    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }

    if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
      parts.add(placemark.postalCode!);
    }

    return parts.join(', ');
  }

  /// Obtiene múltiples direcciones candidatas para una búsqueda.
  static Future<List<String>> searchAddresses(String query) async {
    try {
      if (query.isEmpty) return [];

      final locations = await geocoding.locationFromAddress(query);

      if (locations.isEmpty) return [];

      final addresses = <String>[];
      for (var location in locations) {
        final placemarks = await geocoding.placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          addresses.add(_formatAddress(placemarks.first));
        }
      }

      return addresses;
    } catch (e) {
      print('Error en búsqueda de direcciones: $e');
      return [];
    }
  }

  /// Valida si una dirección es válida y retorna sus coordenadas.
  static Future<bool> validateAddress(String address) async {
    final location = await geocodeAddress(address);
    return location != null;
  }
}
