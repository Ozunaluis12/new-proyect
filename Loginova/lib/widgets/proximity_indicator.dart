import 'package:flutter/material.dart';
import '../services/proximity_service.dart';
import '../themes/app_theme.dart';

/// Widget que muestra el indicador de proximidad del operador a la recogida.
/// Incluye distancia, estado y ETA.
class ProximityIndicator extends StatelessWidget {
  final ProximityInfo proximityInfo;
  // Si es true, se muestra la variante pequeña (chip); si no, la tarjeta
  // expandida con distancia, ETA y aviso.
  final bool isCompact;

  const ProximityIndicator({
    super.key,
    required this.proximityInfo,
    this.isCompact = false,
  });

  /// Color asociado al estado de proximidad actual (verde = muy cerca,
  /// rojo = muy lejos, etc.), reutilizado en ambas variantes del widget.
  Color _getColorForStatus() {
    switch (proximityInfo.status) {
      case ProximityStatus.veryNear:
        return LoginovaColors.success;
      case ProximityStatus.near:
        return LoginovaColors.info;
      case ProximityStatus.far:
        return LoginovaColors.warning;
      case ProximityStatus.veryFar:
        return LoginovaColors.error;
      case ProximityStatus.unknown:
        return LoginovaColors.textSecondary;
    }
  }

  /// Ícono asociado al estado de proximidad actual.
  IconData _getIconForStatus() {
    switch (proximityInfo.status) {
      case ProximityStatus.veryNear:
        return Icons.location_on;
      case ProximityStatus.near:
        return Icons.location_on_outlined;
      case ProximityStatus.far:
        return Icons.navigation;
      case ProximityStatus.veryFar:
        return Icons.directions_car;
      case ProximityStatus.unknown:
        return Icons.location_disabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactView();
    }
    return _buildExpandedView(context);
  }

  /// Variante compacta: un chip con ícono y distancia, para usar en
  /// espacios reducidos como encabezados o listas.
  Widget _buildCompactView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getColorForStatus().withValues(alpha: 0.1),
        border: Border.all(color: _getColorForStatus()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIconForStatus(), color: _getColorForStatus(), size: 16),
          const SizedBox(width: 6),
          Text(
            proximityInfo.distanceFormatted,
            style: TextStyle(
              color: _getColorForStatus(),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Variante expandida: tarjeta con distancia, ETA estimado y un aviso
  /// visual cuando el operador todavía está lejos de la recogida.
  Widget _buildExpandedView(BuildContext context) {
    final eta = ProximityService.getETA(proximityInfo.distanceMeters);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              _getColorForStatus().withValues(alpha: 0.1),
              _getColorForStatus().withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado con ícono y estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getColorForStatus(),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    _getIconForStatus(),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    proximityInfo.message,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _getColorForStatus(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Información de distancia y ETA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn(
                  label: 'Distancia',
                  value: proximityInfo.distanceFormatted,
                  context: context,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: LoginovaColors.textSecondary.withValues(alpha: 0.2),
                ),
                _buildInfoColumn(label: 'ETA', value: eta, context: context),
              ],
            ),
            if (!proximityInfo.isClosed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LoginovaColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 16, color: LoginovaColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El operador está lejos de la recogida',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: LoginovaColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Columna reutilizable con una etiqueta (p. ej. "Distancia" o "ETA")
  /// y su valor destacado, usada en la vista expandida.
  Widget _buildInfoColumn({
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: LoginovaColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _getColorForStatus(),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Widget que muestra solo la distancia en tiempo real, con su propio
/// color según qué tan cerca está el operador (versión más simple que
/// [ProximityIndicator], sin depender de un [ProximityInfo] completo).
class DistanceDisplay extends StatelessWidget {
  final double distanceMeters;
  // Si es false, solo se muestra el valor de distancia sin la etiqueta
  // de arriba (útil para overlays pequeños en el mapa).
  final bool showLabel;

  const DistanceDisplay({
    super.key,
    required this.distanceMeters,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final distanceFormatted = ProximityService.formatDistance(distanceMeters);
    final status = _getStatusForDistance();
    final color = _getColorForStatus(status);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            'Distancia',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: LoginovaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          distanceFormatted,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Clasifica la distancia en umbrales fijos (metros) para determinar
  /// el estado de proximidad, en lugar de reusar el status ya calculado
  /// en [ProximityInfo] (este widget puede recibir solo la distancia).
  ProximityStatus _getStatusForDistance() {
    if (distanceMeters < 500) {
      return ProximityStatus.veryNear;
    } else if (distanceMeters < 1000) {
      return ProximityStatus.near;
    } else if (distanceMeters < 5000) {
      return ProximityStatus.far;
    } else {
      return ProximityStatus.veryFar;
    }
  }

  Color _getColorForStatus(ProximityStatus status) {
    switch (status) {
      case ProximityStatus.veryNear:
        return LoginovaColors.success;
      case ProximityStatus.near:
        return LoginovaColors.info;
      case ProximityStatus.far:
        return LoginovaColors.warning;
      case ProximityStatus.veryFar:
        return LoginovaColors.error;
      case ProximityStatus.unknown:
        return LoginovaColors.textSecondary;
    }
  }
}

/// Widget que muestra un badge (chip con tooltip) indicador de
/// proximidad, pensado para usarse superpuesto sobre el mapa o en
/// tarjetas de recogida dentro de una lista.
class ProximityBadge extends StatelessWidget {
  final ProximityInfo proximityInfo;

  const ProximityBadge({super.key, required this.proximityInfo});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (proximityInfo.status) {
      case ProximityStatus.veryNear:
        color = LoginovaColors.success;
        icon = Icons.check_circle;
        break;
      case ProximityStatus.near:
        color = LoginovaColors.info;
        icon = Icons.location_on;
        break;
      case ProximityStatus.far:
        color = LoginovaColors.warning;
        icon = Icons.navigate_next;
        break;
      case ProximityStatus.veryFar:
        color = LoginovaColors.error;
        icon = Icons.warning;
        break;
      case ProximityStatus.unknown:
        color = LoginovaColors.textSecondary;
        icon = Icons.help;
        break;
    }

    return Tooltip(
      message: proximityInfo.message,
      child: Chip(
        avatar: Icon(icon, size: 16, color: Colors.white),
        label: Text(proximityInfo.distanceFormatted),
        backgroundColor: color,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
