import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/recogida.dart';
import '../services/location_service.dart';
import '../services/proximity_service.dart';

/// Provider que gestiona el cálculo de proximidad en tiempo real.
/// Mantiene actualizada la distancia entre el operador y cada recogida.
class ProximityProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  // Mapa de recogida ID -> ProximityInfo
  final Map<int, ProximityInfo> _proximities = {};
  LocationData? _currentLocation;
  bool _isTracking = false;
  String? _error;
  Timer? _notifyDebounce;
  StreamSubscription<LocationData>? _locationSubscription;

  Map<int, ProximityInfo> get proximities => Map.unmodifiable(_proximities);
  LocationData? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  String? get error => _error;

  /// Obtiene la información de proximidad de una recogida específica.
  ProximityInfo? getProximityForPickup(int pickupId) => _proximities[pickupId];

  /// Inicia el rastreo de proximidad con respecto a una lista de recogidas.
  Future<bool> startProximityTracking(List<Recogida> recogidas) async {
    try {
      _isTracking = true;
      _error = null;
      notifyListeners();

      // Obtener ubicación inicial
      final location = await LocationService.getCurrentLocation();
      if (location == null) {
        _error = 'No se pudo obtener la ubicación inicial';
        _isTracking = false;
        notifyListeners();
        return false;
      }

      _currentLocation = location;
      _updateProximities(recogidas, location);
      notifyListeners();

      // Suscribirse al stream de ubicación. Si ya había una suscripción
      // activa (p. ej. se volvió a entrar a la pantalla), se cancela antes
      // de crear una nueva para no acumular listeners con datos obsoletos.
      await _locationSubscription?.cancel();
      _locationService.startTracking();
      _locationSubscription = _locationService.locationStream.listen(
        (LocationData location) {
          _currentLocation = location;
          _updateProximities(recogidas, location);
          // Debounce de 500ms para no saturar la UI con rebuilds
          _notifyDebounce?.cancel();
          _notifyDebounce = Timer(const Duration(milliseconds: 500), () {
            notifyListeners();
          });
        },
        onError: (e) {
          _error = 'Error en rastreo: $e';
          notifyListeners();
        },
      );

      return true;
    } catch (e) {
      _error = 'Error iniciando rastreo: $e';
      _isTracking = false;
      notifyListeners();
      return false;
    }
  }

  /// Detiene el rastreo de proximidad.
  void stopProximityTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationService.stopTracking();
    _isTracking = false;
    _proximities.clear();
    notifyListeners();
  }

  /// Actualiza las proximidades para todas las recogidas.
  void _updateProximities(
    List<Recogida> recogidas,
    LocationData operatorLocation,
  ) {
    _proximities.clear();

    for (final recogida in recogidas) {
      // Solo calcular proximidad si la recogida tiene coordenadas
      if (recogida.latitud != null && recogida.longitud != null) {
        final proximityInfo = ProximityService.calculateProximity(
          operatorLat: operatorLocation.latitude,
          operatorLng: operatorLocation.longitude,
          pickupLat: recogida.latitud!,
          pickupLng: recogida.longitud!,
        );
        _proximities[recogida.id] = proximityInfo;
      }
    }
  }

  /// Obtiene el estado de proximidad general (la más cercana).
  ProximityStatus? getGeneralProximityStatus() {
    if (_proximities.isEmpty) return null;

    var closestDistance = double.infinity;
    ProximityStatus? closestStatus;

    for (final proximity in _proximities.values) {
      if (proximity.distanceMeters < closestDistance) {
        closestDistance = proximity.distanceMeters;
        closestStatus = proximity.status;
      }
    }

    return closestStatus;
  }

  /// Obtiene las recogidas ordenadas por proximidad.
  List<int> getPickupsSortedByProximity() {
    final sorted = _proximities.entries.toList();
    sorted.sort(
      (a, b) => a.value.distanceMeters.compareTo(b.value.distanceMeters),
    );
    return sorted.map((e) => e.key).toList();
  }

  /// Obtiene las recogidas que están "cerca" (< 1 km).
  List<int> getClosePickups() {
    return _proximities.entries
        .where((e) => e.value.isClosed)
        .map((e) => e.key)
        .toList();
  }

  /// Calcula la distancia total a todas las recogidas.
  double getTotalDistance() {
    return _proximities.values.fold(0, (sum, p) => sum + p.distanceMeters);
  }

  /// Limpia recursos.
  @override
  void dispose() {
    _notifyDebounce?.cancel();
    stopProximityTracking();
    _locationService.dispose();
    super.dispose();
  }
}
