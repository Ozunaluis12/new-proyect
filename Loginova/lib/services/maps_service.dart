import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/app_logger.dart';

/// Información de una ruta entre dos puntos.
class RouteInfo {
  final double distanceMeters;
  final Duration duration;
  final List<LatLng> points; // Polyline points
  final String polylineEncoded;
  final String? summary; // Ej: "I-5 S"

  RouteInfo({
    required this.distanceMeters,
    required this.duration,
    required this.points,
    required this.polylineEncoded,
    this.summary,
  });

  /// Distancia en km
  double get distanceKm => distanceMeters / 1000;

  String get durationFormatted {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }
}

/// Punto geográfico (latitud, longitud)
class LatLng {
  final double latitude;
  final double longitude;

  LatLng({required this.latitude, required this.longitude});

  @override
  String toString() => '$latitude,$longitude';
}

/// Servicio para manejo de rutas y optimización usando Google Directions API.
/// Requiere Google Maps API key con Directions API habilitada.
class MapsService {
  static const String _directionsUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const String _osrmDirectionsBaseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  // TODO: Configurar API Key desde ambiente o configuración
  static String? _apiKey;

  /// Establece la API Key de Google Maps.
  static void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Obtiene la ruta entre dos puntos.
  static Future<RouteInfo?> getRoute({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving',
  }) async {
    if (_apiKey == null) {
      return _getRouteWithOsrm(origin: origin, destination: destination);
    }

    try {
      final url = Uri.parse(_directionsUrl).replace(
        queryParameters: {
          'origin': origin.toString(),
          'destination': destination.toString(),
          'key': _apiKey,
          'mode': travelMode,
          'language': 'es',
        },
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        AppLogger.warn('Error en Directions API: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] != 'OK') {
        AppLogger.warn('Directions API status: ${data['status']}');
        return null;
      }

      if ((data['routes'] as List).isEmpty) {
        AppLogger.debug('No se encontraron rutas');
        return null;
      }

      final route = data['routes'][0] as Map<String, dynamic>;
      final leg = (route['legs'] as List)[0] as Map<String, dynamic>;

      final distanceMeters =
          (leg['distance'] as Map<String, dynamic>)['value'] as int;
      final durationSeconds =
          (leg['duration'] as Map<String, dynamic>)['value'] as int;
      final polylineEncoded =
          (route['overview_polyline'] as Map<String, dynamic>)['points']
              as String;

      final points = _decodePolyline(polylineEncoded);

      return RouteInfo(
        distanceMeters: distanceMeters.toDouble(),
        duration: Duration(seconds: durationSeconds),
        points: points,
        polylineEncoded: polylineEncoded,
        summary: leg['summary'] as String?,
      );
    } catch (e) {
      AppLogger.warn('Error obteniendo ruta: $e', error: e);
      return null;
    }
  }

  /// Fallback sin API key usando OSRM público (ideal para prototipo/demo).
  static Future<RouteInfo?> _getRouteWithOsrm({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final url =
          Uri.parse(
            '$_osrmDirectionsBaseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}',
          ).replace(
            queryParameters: {
              'overview': 'full',
              'geometries': 'polyline',
              'alternatives': 'false',
              'steps': 'false',
            },
          );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        AppLogger.warn('Error en OSRM: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') {
        AppLogger.warn('OSRM status: ${data['code']}');
        return null;
      }

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) {
        AppLogger.debug('No se encontraron rutas en OSRM');
        return null;
      }

      final route = routes.first as Map<String, dynamic>;
      final distanceMeters = (route['distance'] as num).toDouble();
      final durationSeconds = (route['duration'] as num).round();
      final polylineEncoded = route['geometry'] as String;

      return RouteInfo(
        distanceMeters: distanceMeters,
        duration: Duration(seconds: durationSeconds),
        points: _decodePolyline(polylineEncoded),
        polylineEncoded: polylineEncoded,
        summary: 'Ruta estimada (OSRM)',
      );
    } catch (e) {
      AppLogger.warn('Error obteniendo ruta en OSRM: $e', error: e);
      return null;
    }
  }

  /// Obtiene rutas optimizadas para múltiples paradas.
  /// Usa Waypoints para calcular la ruta más eficiente.
  static Future<RouteInfo?> getOptimizedRoute({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> waypoints,
    bool optimizeWaypoints = true,
  }) async {
    if (_apiKey == null) {
      AppLogger.warn('API Key no configurada');
      return null;
    }

    try {
      final waypointsStr = waypoints.map((w) => w.toString()).join('|');

      final url = Uri.parse(_directionsUrl).replace(
        queryParameters: {
          'origin': origin.toString(),
          'destination': destination.toString(),
          'waypoints': waypointsStr,
          'optimize': optimizeWaypoints ? 'true' : 'false',
          'key': _apiKey,
          'mode': 'driving',
          'language': 'es',
        },
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        AppLogger.warn('Error en Directions API: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] != 'OK') {
        AppLogger.warn('Directions API status: ${data['status']}');
        return null;
      }

      if ((data['routes'] as List).isEmpty) {
        AppLogger.debug('No se encontraron rutas');
        return null;
      }

      // Combina todas las piernas (legs) en una sola ruta
      final route = data['routes'][0] as Map<String, dynamic>;
      final legs = route['legs'] as List;

      double totalDistanceMeters = 0;
      int totalDurationSeconds = 0;
      final polylineEncoded =
          (route['overview_polyline'] as Map<String, dynamic>)['points']
              as String;

      for (var leg in legs) {
        totalDistanceMeters +=
            (leg['distance'] as Map<String, dynamic>)['value'] as int;
        totalDurationSeconds +=
            (leg['duration'] as Map<String, dynamic>)['value'] as int;
      }

      final points = _decodePolyline(polylineEncoded);

      return RouteInfo(
        distanceMeters: totalDistanceMeters.toDouble(),
        duration: Duration(seconds: totalDurationSeconds),
        points: points,
        polylineEncoded: polylineEncoded,
      );
    } catch (e) {
      AppLogger.warn('Error obteniendo ruta optimizada: $e', error: e);
      return null;
    }
  }

  /// Decodifica un polyline codificado de Google Maps.
  /// Convierte el string comprimido en lista de coordenadas.
  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;

      while (true) {
        final byte = encoded.codeUnitAt(index) - 63;
        index++;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) break;
      }

      final dlat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lat += dlat;

      result = 0;
      shift = 0;

      while (true) {
        final byte = encoded.codeUnitAt(index) - 63;
        index++;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) break;
      }

      final dlng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lng += dlng;

      points.add(LatLng(latitude: lat / 1e5, longitude: lng / 1e5));
    }

    return points;
  }

  /// Calcula la matriz de distancias entre múltiples puntos.
  /// Útil para comparar tiempos de viaje.
  static Future<Map<String, dynamic>?> getDistanceMatrix({
    required List<LatLng> origins,
    required List<LatLng> destinations,
  }) async {
    if (_apiKey == null) {
      AppLogger.warn('API Key no configurada');
      return null;
    }

    try {
      const url = 'https://maps.googleapis.com/maps/api/distancematrix/json';

      final originsStr = origins.map((o) => o.toString()).join('|');
      final destinationsStr = destinations.map((d) => d.toString()).join('|');

      final response = await http.get(
        Uri.parse(url).replace(
          queryParameters: {
            'origins': originsStr,
            'destinations': destinationsStr,
            'key': _apiKey,
            'mode': 'driving',
            'language': 'es',
          },
        ),
      );

      if (response.statusCode != 200) {
        AppLogger.warn('Error en Distance Matrix API: ${response.statusCode}');
        return null;
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.warn('Error obteniendo matriz de distancias: $e', error: e);
      return null;
    }
  }

  /// Obtiene estimación de costo de viaje (tiempo y distancia).
  static Future<Map<String, String>?> getTravelEstimate({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final route = await getRoute(origin: origin, destination: destination);

    if (route == null) return null;

    return {
      'distancia': '${route.distanceKm.toStringAsFixed(1)} km',
      'duracion': route.durationFormatted,
      'tiempo_minutos': route.duration.inMinutes.toString(),
    };
  }
}
