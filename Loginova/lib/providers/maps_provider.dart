import 'package:flutter/foundation.dart';
import '../services/maps_service.dart';
import '../services/location_service.dart';

/// Provider que gestiona las rutas y datos de mapas.
/// Maneja obtención de rutas, cálculos de distancia y optimización de waypoints.
class MapsProvider extends ChangeNotifier {
  RouteInfo? _currentRoute;
  RouteInfo? _optimizedRoute;
  bool _isLoadingRoute = false;
  String? _error;
  List<LatLng>? _waypoints;

  RouteInfo? get currentRoute => _currentRoute;
  RouteInfo? get optimizedRoute => _optimizedRoute;
  bool get isLoadingRoute => _isLoadingRoute;
  String? get error => _error;
  List<LatLng>? get waypoints => _waypoints;

  /// Obtiene una ruta simple entre dos puntos.
  Future<bool> getRoute({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving',
  }) async {
    _isLoadingRoute = true;
    _error = null;
    notifyListeners();

    try {
      final route = await MapsService.getRoute(
        origin: origin,
        destination: destination,
        travelMode: travelMode,
      );

      if (route != null) {
        _currentRoute = route;
        notifyListeners();
        return true;
      } else {
        _error = 'No se encontró ruta disponible';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error obteniendo ruta: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoadingRoute = false;
      notifyListeners();
    }
  }

  /// Obtiene una ruta optimizada con múltiples paradas (waypoints).
  /// Calcula automáticamente el orden más eficiente.
  Future<bool> getOptimizedRoute({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> waypoints,
  }) async {
    _isLoadingRoute = true;
    _error = null;
    _waypoints = waypoints;
    notifyListeners();

    try {
      final route = await MapsService.getOptimizedRoute(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
        optimizeWaypoints: true,
      );

      if (route != null) {
        _optimizedRoute = route;
        notifyListeners();
        return true;
      } else {
        _error = 'No se encontró ruta optimizada disponible';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error obteniendo ruta optimizada: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoadingRoute = false;
      notifyListeners();
    }
  }

  /// Obtiene una estimación rápida de tiempo y distancia.
  Future<Map<String, String>?> getTravelEstimate({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      return await MapsService.getTravelEstimate(
        origin: origin,
        destination: destination,
      );
    } catch (e) {
      _error = 'Error obteniendo estimación: $e';
      notifyListeners();
      return null;
    }
  }

  /// Calcula la distancia entre dos puntos en metros.
  double calculateDistance({
    required LatLng point1,
    required LatLng point2,
  }) {
    return LocationService.calculateDistance(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Obtiene la matriz de distancias entre múltiples puntos.
  Future<Map<String, dynamic>?> getDistanceMatrix({
    required List<LatLng> origins,
    required List<LatLng> destinations,
  }) async {
    try {
      return await MapsService.getDistanceMatrix(
        origins: origins,
        destinations: destinations,
      );
    } catch (e) {
      _error = 'Error obteniendo matriz: $e';
      notifyListeners();
      return null;
    }
  }

  /// Limpia la ruta actual.
  void clearRoute() {
    _currentRoute = null;
    _optimizedRoute = null;
    _waypoints = null;
    _error = null;
    notifyListeners();
  }

  /// Limpia los errores.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
