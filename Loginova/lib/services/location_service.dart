import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

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
class LocationService {
  static const int _updateIntervalSeconds = 30; // Actualizar cada 30 segundos
  static const int _fastestIntervalSeconds = 10; // Mínimo intervalo
  static const double _distanceFilter = 5; // Mínimo de metros para actualizar

  StreamSubscription<Position>? _positionStream;
  Timer? _uploadTimer;
  Position? _lastPosition;
  bool _isTracking = false;

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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: _distanceFilter,
        ),
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      return null;
    }
  }

  /// Inicia el rastreo continuo de ubicación.
  void startTracking() {
    if (_isTracking) return;

    _isTracking = true;
    
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _distanceFilter,
      timeLimit: const Duration(seconds: _updateIntervalSeconds),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _lastPosition = position;
      _uploadLocationToBackend(position);
    });

    print('Rastreo de ubicación iniciado');
  }

  /// Detiene el rastreo de ubicación.
  void stopTracking() {
    _isTracking = false;
    _positionStream?.cancel();
    _uploadTimer?.cancel();
    print('Rastreo de ubicación detenido');
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
      print('Error enviando ubicación: $e');
      return false;
    }
  }

  /// Obtiene la dirección a partir de coordenadas (reverse geocoding).
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return '${p.street}, ${p.locality}, ${p.administrativeArea}';
      }
    } catch (e) {
      print('Error en reverse geocoding: $e');
    }
    return null;
  }

  /// Obtiene coordenadas a partir de una dirección (forward geocoding).
  static Future<LocationData?> getCoordinatesFromAddress(
    String address,
  ) async {
    try {
      final locations = await geocoding.locationFromAddress(address);

      if (locations.isNotEmpty) {
        final loc = locations.first;
        return LocationData(
          latitude: loc.latitude,
          longitude: loc.longitude,
          accuracy: 0,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error en geocoding: $e');
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
  }
}

