import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../services/maps_service.dart';

/// Widget que muestra información sobre una ruta calculada.
class RouteInfoCard extends StatelessWidget {
  final RouteInfo? route;
  final VoidCallback? onClose;

  const RouteInfoCard({
    Key? key,
    required this.route,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (route == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Información de la Ruta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.straighten,
              label: 'Distancia',
              value: '${route!.distanceKm.toStringAsFixed(1)} km',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.timer,
              label: 'Tiempo estimado',
              value: route!.durationFormatted,
            ),
            if (route!.summary != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _InfoRow(
                  icon: Icons.directions,
                  label: 'Ruta',
                  value: route!.summary ?? '',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget auxiliar para mostrar filas de información.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget que muestra un botón para calcular rutas.
class RouteCalculatorButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const RouteCalculatorButton({
    Key? key,
    this.label = 'Calcular Ruta',
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.directions),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Widget que muestra opciones para rastreo de ubicación.
class LocationTrackingWidget extends StatefulWidget {
  const LocationTrackingWidget({Key? key}) : super(key: key);

  @override
  State<LocationTrackingWidget> createState() => _LocationTrackingWidgetState();
}

class _LocationTrackingWidgetState extends State<LocationTrackingWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rastreo de Ubicación',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationProvider.isTracking
                              ? 'Rastreando...'
                              : 'No rastreando',
                          style: TextStyle(
                            fontSize: 14,
                            color: locationProvider.isTracking
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (locationProvider.currentLocation != null)
                          Text(
                            'Lat: ${locationProvider.currentLocation!.latitude.toStringAsFixed(4)}, '
                            'Lon: ${locationProvider.currentLocation!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: locationProvider.isTracking
                          ? locationProvider.stopTracking
                          : locationProvider.startTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: locationProvider.isTracking
                            ? Colors.red
                            : Colors.green,
                      ),
                      child: Text(
                        locationProvider.isTracking ? 'Detener' : 'Iniciar',
                      ),
                    ),
                  ],
                ),
                if (locationProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Error: ${locationProvider.error}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
