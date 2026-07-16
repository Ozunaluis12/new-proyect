import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/recogida.dart';
import '../providers/recogida_provider.dart';
import '../providers/location_provider.dart';
import '../providers/maps_provider.dart';
import '../providers/proximity_provider.dart';
import '../services/location_service.dart';
import '../services/maps_service.dart' as maps_service;
import '../services/proximity_service.dart';
import '../themes/app_theme.dart';
import '../utils/app_logger.dart';
import '../widgets/menu_drawer.dart';
import '../widgets/proximity_indicator.dart';

/// Pantalla interactiva que muestra recogidas en un mapa con ubicación en tiempo real del operador.
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

/// Estado de [MapaScreen]: mantiene la ubicación GPS del operador, los
/// marcadores del mapa (operador + recogidas), el estado de la ruta
/// calculada con "Cómo llegar" y coordina el rastreo de proximidad vía
/// [ProximityProvider].
class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  LocationData? _operatorLocation;
  bool _showOperatorMarker = false;
  Timer? _markerDebounce;

  List<LatLng> _rutaPuntos = [];
  maps_service.RouteInfo? _rutaInfo;
  bool _calculandoRuta = false;

  // Ubicación por defecto mientras carga el GPS (usada solo como fallback)
  static const LatLng _ubicacionFallback = LatLng(6.2442, -75.5812);
  static const double _zoomInicial =
      15; // Zoom más cercano para ver la ubicación real

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocationTracking();
    });
  }

  /// Inicializa el rastreo de ubicación del operador
  Future<void> _initializeLocationTracking() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      final proximityProvider = Provider.of<ProximityProvider>(
        context,
        listen: false,
      );
      final recogidaProvider = Provider.of<RecogidaProvider>(
        context,
        listen: false,
      );

      // Obtener ubicación actual
      await locationProvider.getCurrentLocation();

      if (mounted && locationProvider.currentLocation != null) {
        final loc = locationProvider.currentLocation!;
        setState(() {
          _operatorLocation = loc;
          _showOperatorMarker = true;
        });

        // Mover el mapa a la ubicación real del operador
        _mapController.move(LatLng(loc.latitude, loc.longitude), _zoomInicial);

        // Iniciar rastreo de proximidad
        await proximityProvider.startProximityTracking(
          recogidaProvider.recogidas,
        );
      } else if (mounted) {
        // Si no hay ubicación, mostrar indicador de error amigable
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa el GPS para ver tu ubicación en el mapa'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      AppLogger.warn('Error inicializando ubicación: $e', error: e);
    }
  }

  @override
  void dispose() {
    _markerDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Actualiza marcadores con debounce para evitar rebuilds masivos
  void _scheduleMarkersUpdate(
    List<Recogida> recogidas,
    Map<int, ProximityInfo> proximities,
    LocationData? location,
  ) {
    _markerDebounce?.cancel();
    _markerDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final newMarkers = List<Marker>.from(
        _buildPickupMarkers(recogidas, proximities),
      );
      if (_showOperatorMarker && location != null) {
        final prevLocation = _operatorLocation;
        _operatorLocation = location;
        // Mover el mapa automáticamente si la ubicación cambió significativamente (primera vez)
        if (prevLocation == null) {
          _mapController.move(
            LatLng(location.latitude, location.longitude),
            _zoomInicial,
          );
        }
        newMarkers.add(_buildOperatorMarker()!);
      }
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
      });
    });
  }

  /// Convierte LocationData a LatLng
  LatLng _locationDataToLatLng(LocationData location) {
    return LatLng(location.latitude, location.longitude);
  }

  /// Construye el marcador del operador (ubicación actual)
  Marker? _buildOperatorMarker() {
    if (_operatorLocation == null) return null;

    return Marker(
      point: _locationDataToLatLng(_operatorLocation!),
      width: 50,
      height: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: LoginovaColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: LoginovaColors.primary.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 2),
          const Text(
            'Tu ubicación',
            style: TextStyle(
              fontSize: 10,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construye marcadores para las recogidas
  List<Marker> _buildPickupMarkers(
    List<Recogida> recogidas,
    Map<int, ProximityInfo> proximities,
  ) {
    final markers = <Marker>[];

    for (final recogida in recogidas) {
      if (recogida.latitud == null || recogida.longitud == null) continue;

      final coords = LatLng(recogida.latitud!, recogida.longitud!);
      final proximityInfo = proximities[recogida.id];
      final color = _getColorPorEstado(recogida.estado);
      final isClosed = proximityInfo?.isClosed ?? false;

      markers.add(
        Marker(
          point: coords,
          width: isClosed ? 60 : 50,
          height: isClosed ? 60 : 50,
          child: GestureDetector(
            onTap: () => _mostrarDetallesRecogida(recogida, proximityInfo),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isClosed)
                  Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.inventory_2,
                    color: Colors.white,
                    size: isClosed ? 24 : 20,
                  ),
                ),
                if (isClosed)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: LoginovaColors.success,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  /// Obtiene el color según el estado de la recogida
  Color _getColorPorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return LoginovaColors.warning;
      case 'asignada':
        return LoginovaColors.info;
      case 'en ruta':
        return LoginovaColors.secondary;
      case 'recogida':
        return LoginovaColors.success;
      case 'cancelada':
        return LoginovaColors.error;
      default:
        return LoginovaColors.textSecondary;
    }
  }

  /// Calcula y dibuja en el mapa la ruta desde la ubicación actual hasta una
  /// recogida (usa OSRM, la misma fuente gratuita que ya usa el resto del
  /// mapa; nunca sale de la app hacia Google Maps ni otra app externa).
  Future<void> _calcularRuta(Recogida recogida) async {
    if (recogida.latitud == null || recogida.longitud == null) return;

    final ubicacionActual = _operatorLocation;
    if (ubicacionActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activa el GPS para calcular cómo llegar'),
        ),
      );
      return;
    }

    setState(() => _calculandoRuta = true);

    final mapsProvider = Provider.of<MapsProvider>(context, listen: false);
    final exito = await mapsProvider.getRoute(
      origin: maps_service.LatLng(
        latitude: ubicacionActual.latitude,
        longitude: ubicacionActual.longitude,
      ),
      destination: maps_service.LatLng(
        latitude: recogida.latitud!,
        longitude: recogida.longitud!,
      ),
    );

    if (!mounted) return;
    setState(() => _calculandoRuta = false);

    if (!exito || mapsProvider.currentRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo calcular la ruta')),
      );
      return;
    }

    final ruta = mapsProvider.currentRoute!;
    final puntos = ruta.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    setState(() {
      _rutaInfo = ruta;
      _rutaPuntos = puntos;
    });

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(puntos),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  void _limpiarRuta() {
    setState(() {
      _rutaInfo = null;
      _rutaPuntos = [];
    });
  }

  /// Muestra detalles de recogida con información de proximidad
  void _mostrarDetallesRecogida(
    Recogida recogida,
    ProximityInfo? proximityInfo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recogida #${recogida.id}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getColorPorEstado(
                        recogida.estado,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      recogida.estado,
                      style: TextStyle(
                        color: _getColorPorEstado(recogida.estado),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Información de proximidad si está disponible
              if (proximityInfo != null) ...[
                ProximityIndicator(proximityInfo: proximityInfo),
                const SizedBox(height: 16),
              ],

              // Detalles de la recogida
              _buildDetailRow(
                'Cliente',
                (recogida.clienteNombre?.isNotEmpty ?? false)
                    ? recogida.clienteNombre!
                    : '#${recogida.clienteId}',
              ),
              _buildDetailRow(
                'Operador',
                recogida.usuarioId == null
                    ? 'Sin asignar'
                    : (recogida.usuarioNombre?.isNotEmpty ?? false)
                    ? recogida.usuarioNombre!
                    : '#${recogida.usuarioId}',
              ),
              _buildDetailRow(
                'Cantidad de paquetes',
                '${recogida.cantidadPaquetes}',
              ),

              if (recogida.latitud != null && recogida.longitud != null) ...[
                _buildDetailRow(
                  'Coordenadas',
                  '${recogida.latitud!.toStringAsFixed(4)}, ${recogida.longitud!.toStringAsFixed(4)}',
                ),
              ],

              if ((recogida.observaciones ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Observaciones', recogida.observaciones!),
              ],

              const SizedBox(height: 20),
              if (recogida.latitud != null && recogida.longitud != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _calcularRuta(recogida);
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Cómo llegar'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye una fila de detalle
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MenuDrawer(currentRoute: '/mapa'),
      appBar: AppBar(
        title: const Text('Mapa de Recogidas en Tiempo Real'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              // Centrar en ubicación del operador
              if (_operatorLocation != null) {
                _mapController.move(
                  _locationDataToLatLng(_operatorLocation!),
                  _zoomInicial,
                );
              }
            },
            tooltip: 'Ir a mi ubicación',
          ),
        ],
      ),
      body: Consumer3<RecogidaProvider, LocationProvider, ProximityProvider>(
        builder:
            (
              context,
              recogidaProvider,
              locationProvider,
              proximityProvider,
              _,
            ) {
              // Programar actualización de marcadores con debounce. Se llama
              // siempre (incluso sin recogidas) para que la ubicación del
              // operador se muestre de inmediato, no solo cuando ya existe
              // al menos una recogida.
              _scheduleMarkersUpdate(
                recogidaProvider.recogidas,
                proximityProvider.proximities,
                locationProvider.currentLocation,
              );

              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _operatorLocation != null
                          ? LatLng(
                              _operatorLocation!.latitude,
                              _operatorLocation!.longitude,
                            )
                          : _ubicacionFallback,
                      initialZoom: _zoomInicial,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.loginova.app',
                      ),
                      if (_rutaPuntos.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _rutaPuntos,
                              strokeWidth: 5,
                              color: LoginovaColors.primary,
                            ),
                          ],
                        ),
                      MarkerLayer(markers: _markers),
                    ],
                  ),

                  // Indicador de carga
                  if (recogidaProvider.cargando)
                    const Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.white,
                      ),
                    ),

                  // Panel de información en la esquina
                  if (proximityProvider.proximities.isNotEmpty)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen de Recogidas',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem(
                                  label: 'Cercanas',
                                  value: proximityProvider
                                      .getClosePickups()
                                      .length
                                      .toString(),
                                  color: LoginovaColors.success,
                                ),
                                _buildSummaryItem(
                                  label: 'Total',
                                  value: proximityProvider.proximities.length
                                      .toString(),
                                  color: LoginovaColors.info,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Tarjeta de ruta activa (distancia, tiempo, cancelar)
                  if (_rutaInfo != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.directions,
                              color: LoginovaColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_rutaInfo!.distanceKm.toStringAsFixed(1)} km · ${_rutaInfo!.durationFormatted}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Ruta hacia la recogida',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Cancelar ruta',
                              onPressed: _limpiarRuta,
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_calculandoRuta)
                    const Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.white,
                      ),
                    ),

                  // Botones de acción
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          heroTag: 'refresh_pickups',
                          onPressed: () async {
                            await recogidaProvider.cargarRecogidas();
                          },
                          tooltip: 'Recargar recogidas',
                          child: const Icon(Icons.refresh),
                        ),
                        const SizedBox(height: 12),
                        FloatingActionButton(
                          heroTag: 'center_map',
                          mini: true,
                          onPressed: () async {
                            if (locationProvider.currentLocation != null) {
                              _mapController.move(
                                _locationDataToLatLng(
                                  locationProvider.currentLocation!,
                                ),
                                _zoomInicial,
                              );
                            }
                          },
                          tooltip: 'Ir a mi ubicación',
                          child: const Icon(Icons.my_location),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
