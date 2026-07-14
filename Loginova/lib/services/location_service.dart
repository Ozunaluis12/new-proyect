import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import '../utils/app_logger.dart';
import 'geocoding_service.dart';

/// Resultado de ubicación actual del dispositivo.
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Servicio para manejo de ubicaciones geográficas en tiempo real.
/// Maneja permisos, obtención de coordenadas y envío periódico al backend.
/// Emite actualizaciones de ubicación mediante Stream para UI reactivo.
class LocationService {
  static const int _updateIntervalSeconds = 15; // Actualizar cada 15 segundos
  static const int _distanceFilterMeters =
      5; // Mínimo de metros para actualizar

  StreamSubscription<Position>? _positionStream;
  Timer? _uploadTimer;
  Position? _lastPosition;
  bool _isTracking = false;

  // StreamController para emitir ubicaciones en tiempo real
  final StreamController<LocationData> _locationController =
      StreamController<LocationData>.broadcast();

  /// Stream de ubicaciones en tiempo real
  Stream<LocationData> get locationStream => _locationController.stream;

  /// Solicita permisos de ubicación al dispositivo.
  static Future<bool> requestPermission() async {
    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      final newPermission = await Geolocator.requestPermission();
      return newPermission == LocationPermission.whileInUse ||
          newPermission == LocationPermission.always;
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openLocationSettings();
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Verifica si el GPS está habilitado en el dispositivo.
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Obtiene la posición actual del dispositivo.
  static Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: _updateIntervalSeconds),
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      AppLogger.warn('Error obteniendo ubicación: $e', error: e);
      return null;
    }
  }

  /// Inicia el rastreo continuo de ubicación.
  void startTracking() {
    if (_isTracking) return;

    _isTracking = true;

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _distanceFilterMeters,
      timeLimit: const Duration(seconds: _updateIntervalSeconds),
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _lastPosition = position;
            // Emitir ubicación mediante stream
            final locationData = LocationData(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
              timestamp: DateTime.now(),
            );
            _locationController.add(locationData);
            // Enviar al backend
            _uploadLocationToBackend(position);
          },
          onError: (e) {
            AppLogger.warn('Error en stream de ubicación: $e', error: e);
          },
        );

    AppLogger.info('Rastreo de ubicación iniciado');
  }

  /// Detiene el rastreo de ubicación.
  void stopTracking() {
    _isTracking = false;
    _positionStream?.cancel();
    _uploadTimer?.cancel();
    AppLogger.info('Rastreo de ubicación detenido');
  }

  /// Sube la ubicación actual al backend.
  Future<bool> _uploadLocationToBackend(Position position) async {
    try {
      if (ApiService.token == null) return false;

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/ubicaciones'),
        headers: ApiService.jsonHeaders,
        body: jsonEncode({
          'latitud': position.latitude,
          'longitud': position.longitude,
          'precisionMetros': position.accuracy,
          'velocidad': position.speed,
          'fechaRegistro': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      AppLogger.warn('Error enviando ubicación: $e', error: e);
      return false;
    }
  }

  /// Obtiene la dirección a partir de coordenadas (reverse geocoding).
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      return await GeocodingService.reverseGeocode(latitude, longitude);
    } catch (e) {
      AppLogger.warn('Error en reverse geocoding: $e', error: e);
    }
    return null;
  }

  /// Obtiene coordenadas a partir de una dirección (forward geocoding).
  static Future<LocationData?> getCoordinatesFromAddress(String address) async {
    try {
      return await GeocodingService.geocodeAddress(address);
    } catch (e) {
      AppLogger.warn('Error en geocoding: $e', error: e);
    }
    return null;
  }

  /// Calcula la distancia en metros entre dos coordenadas.
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Retorna la última posición conocida.
  Position? getLastPosition() => _lastPosition;

  /// Retorna si está actualmente rastreando.
  bool isTracking() => _isTracking;

  /// Libera recursos.
  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
