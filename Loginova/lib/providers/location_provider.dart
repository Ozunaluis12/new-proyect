import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/location_service.dart';

/// Provider que gestiona el estado del rastreo de ubicación.
/// Proporciona acceso a la posición actual y controla el inicio/parada del rastreo.
/// Emite cambios de ubicación en tiempo real mediante Stream.
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  LocationData? _currentLocation;
  bool _isTracking = false;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<LocationData>? _locationSubscription;

  LocationData? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Stream de cambios de ubicación para escuchar en tiempo real
  Stream<LocationData> get locationStream => _locationService.locationStream;

  /// Obtiene la ubicación actual del dispositivo.
  Future<bool> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final location = await LocationService.getCurrentLocation();
      if (location != null) {
        _currentLocation = location;
        notifyListeners();
        return true;
      } else {
        _error = 'No se pudo obtener la ubicación';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia el rastreo continuo de ubicación.
  Future<bool> startTracking() async {
    try {
      final hasPermission = await LocationService.requestPermission();
      if (!hasPermission) {
        _error = 'Permiso de ubicación denegado';
        notifyListeners();
        return false;
      }

      final isEnabled = await LocationService.isLocationServiceEnabled();
      if (!isEnabled) {
        _error = 'Servicio de ubicación deshabilitado';
        notifyListeners();
        return false;
      }

      _locationService.startTracking();
      _isTracking = true;
      _error = null;
      notifyListeners();

      // Si ya había una suscripción activa (p. ej. startTracking() se llamó
      // dos veces sin detener la anterior), se cancela antes de crear una
      // nueva para no dejarla huérfana escuchando en segundo plano.
      await _locationSubscription?.cancel();

      // Suscribirse al stream de ubicación para emitir cambios
      _locationSubscription = _locationService.locationStream.listen(
        (LocationData location) {
          _currentLocation = location;
          notifyListeners();
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

  /// Detiene el rastreo de ubicación.
  void stopTracking() {
    _locationService.stopTracking();
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
    notifyListeners();
  }

  /// Obtiene la dirección de la ubicación actual.
  Future<String?> getAddressFromCurrentLocation() async {
    if (_currentLocation == null) return null;
    return LocationService.getAddressFromCoordinates(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
    );
  }

  /// Limpia recursos.
  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}
