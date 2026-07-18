import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/permission_constants.dart';
import '../models/recogida.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../themes/app_theme.dart';
import '../widgets/llamar_cliente_button.dart';
import 'cambiar_estado_recogida_screen.dart';
import 'editar_recogida_screen.dart';
import 'evidencia_screen.dart';
import 'historial_estados_screen.dart';

/// Pantalla profesional que muestra los detalles completos de una recogida.
class DetalleRecogidaScreen extends StatefulWidget {
  final Recogida recogida;

  const DetalleRecogidaScreen({super.key, required this.recogida});

  @override
  State<DetalleRecogidaScreen> createState() => _DetalleRecogidaScreenState();
}

/// Estado de [DetalleRecogidaScreen]. Mantiene una copia local mutable de la
/// recogida (`_recogida`) para reflejar de inmediato en pantalla los cambios
/// que vienen de vuelta de las pantallas de editar / cambiar estado /
/// agregar evidencia, sin depender de que el provider recargue la lista.
class _DetalleRecogidaScreenState extends State<DetalleRecogidaScreen> {
  late Recogida _recogida;
  late List<String> _evidencias;

  @override
  void initState() {
    super.initState();
    _recogida = widget.recogida;
    _evidencias = List<String>.from(_recogida.evidencias);
  }

  /// Abre la edición de datos generales de la recogida y, si vuelve con una
  /// versión actualizada, refresca el estado local de esta pantalla.
  Future<void> _editarRecogida() async {
    final actualizada = await Navigator.push<Recogida>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarRecogidaScreen(recogida: _recogida),
      ),
    );

    if (actualizada != null && mounted) {
      setState(() {
        _recogida = actualizada;
        _evidencias = List<String>.from(actualizada.evidencias);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recogida actualizada correctamente')),
      );
    }
  }

  /// Abre la captura de una foto de evidencia suelta (fuera del flujo de
  /// cambio de estado) y, de subirse, la agrega a la lista local de
  /// evidencias mostradas en la grilla.
  Future<void> _agregarEvidencia() async {
    final evidenciaPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => EvidenciaScreen(recogidaId: _recogida.id),
      ),
    );

    if (evidenciaPath != null && evidenciaPath.trim().isNotEmpty && mounted) {
      setState(() {
        _evidencias = [..._evidencias, evidenciaPath];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evidencia agregada correctamente')),
      );
    }
  }

  /// Abre [CambiarEstadoRecogidaScreen] (donde ocurre la reasignación de
  /// dueño y responsable del dinero) y sincroniza el resultado en pantalla.
  Future<void> _cambiarEstado() async {
    final actualizada = await Navigator.push<Recogida>(
      context,
      MaterialPageRoute(
        builder: (_) => CambiarEstadoRecogidaScreen(recogida: _recogida),
      ),
    );

    if (actualizada != null && mounted) {
      setState(() {
        _recogida = actualizada;
        _evidencias = List<String>.from(actualizada.evidencias);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado correctamente')),
      );
    }
  }

  /// Obtiene el color según el estado de la recogida
  Color _getEstadoColor(String estado) {
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

  /// Obtiene el ícono según el estado de la recogida
  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.hourglass_empty;
      case 'asignada':
        return Icons.assignment;
      case 'en ruta':
        return Icons.local_shipping;
      case 'recogida':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getEstadoColor(_recogida.estado);
    final icon = _getEstadoIcon(_recogida.estado);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Recogida'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado actual
              _buildEstadoCard(color, icon),
              const SizedBox(height: 24),

              // Información general
              _buildSectionTitle('Información General'),
              const SizedBox(height: 12),
              _buildInfoCard(),
              const SizedBox(height: 24),

              // Información de cliente y operador
              _buildSectionTitle('Asignación'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.person,
                      label: 'Cliente',
                      value: (_recogida.clienteNombre?.isNotEmpty ?? false)
                          ? _recogida.clienteNombre!
                          : '#${_recogida.clienteId}',
                      color: LoginovaColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.engineering,
                      label: 'Operador',
                      value: _recogida.usuarioId == null
                          ? 'Sin asignar'
                          : (_recogida.usuarioNombre?.isNotEmpty ?? false)
                          ? _recogida.usuarioNombre!
                          : '#${_recogida.usuarioId}',
                      color: LoginovaColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LlamarClienteButton(
                nombreCliente: _recogida.clienteNombre,
                telefono: _recogida.clienteTelefono,
              ),
              const SizedBox(height: 24),

              if (_recogida.dineroRecibido ||
                  (_recogida.montoCobrado ?? 0) > 0) ...[
                _buildSectionTitle('Ingresos'),
                const SizedBox(height: 12),
                _buildInfoCardIngresos(),
                const SizedBox(height: 24),
              ],

              // Paquetes
              _buildSectionTitle('Paquetes'),
              const SizedBox(height: 12),
              _buildPackagesCard(),
              const SizedBox(height: 24),

              // Observaciones
              if ((_recogida.observaciones ?? '').isNotEmpty) ...[
                _buildSectionTitle('Observaciones'),
                const SizedBox(height: 12),
                _buildObservacionesCard(),
                const SizedBox(height: 24),
              ],

              // Evidencias
              _buildSectionTitle('Evidencias'),
              const SizedBox(height: 12),
              _buildEvidenciasSection(),
              const SizedBox(height: 24),

              // Botones de acción
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la tarjeta de estado
  Widget _buildEstadoCard(Color color, IconData icon) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado Actual',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _recogida.estado,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta de información general
  Widget _buildInfoCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: LoginovaColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildInfoRow('ID de Recogida', '#${_recogida.id}'),
            const Divider(height: 16),
            _buildInfoRow(
              'Cantidad de Paquetes',
              '${_recogida.cantidadPaquetes} paquetes',
            ),
            if (_recogida.fechaProgramada != null) ...[
              const Divider(height: 16),
              _buildInfoRow(
                'Horario límite',
                _formatearFechaHora(_recogida.fechaProgramada!),
                valueColor: _recogida.horarioVencido
                    ? LoginovaColors.error
                    : _recogida.horarioProximoAVencer()
                    ? LoginovaColors.warning
                    : null,
              ),
            ],
            if (_recogida.fechaRecogida != null) ...[
              const Divider(height: 16),
              _buildInfoRow(
                'Completada',
                _formatearFechaHora(_recogida.fechaRecogida!),
                valueColor: LoginovaColors.success,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Formatea una fecha/hora local como "dd/MM/yyyy HH:mm" sin depender del
  /// paquete intl.
  String _formatearFechaHora(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final hh = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha.year} $hh:$min';
  }

  Widget _buildInfoCardIngresos() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: LoginovaColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              'Dinero recibido',
              _recogida.dineroRecibido ? 'Sí' : 'No',
            ),
            const Divider(height: 16),
            _buildInfoRow(
              'Monto cobrado',
              _recogida.montoCobrado == null
                  ? 'Sin monto'
                  : '\$${_recogida.montoCobrado!.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una fila de información
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: LoginovaColors.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  /// Construye un elemento de detalle
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: LoginovaColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta de paquetes
  Widget _buildPackagesCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LoginovaColors.secondary.withValues(alpha: 0.1),
          border: Border.all(
            color: LoginovaColors.secondary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: LoginovaColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory_2, color: LoginovaColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total de Paquetes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LoginovaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_recogida.cantidadPaquetes}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: LoginovaColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta de observaciones
  Widget _buildObservacionesCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Notas',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: LoginovaColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _recogida.observaciones ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el título de una sección
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: LoginovaColors.primary,
      ),
    );
  }

  /// Construye la sección de evidencias
  Widget _buildEvidenciasSection() {
    if (_evidencias.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Icon(
                Icons.image_not_supported,
                size: 48,
                color: LoginovaColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No hay evidencias',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LoginovaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _evidencias.length,
      itemBuilder: (context, index) {
        final url = _evidencias[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                headers: {
                  if (ApiService.token != null)
                    'Authorization': 'Bearer ${ApiService.token}',
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: LoginovaColors.background,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: LoginovaColors.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No se pudo cargar',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Evidencia ${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construye los botones de acción. Quien tiene permiso de editar
  /// recogidas ve las acciones de edición completa; si no, pero tiene
  /// permiso de cambiar estado y/o subir evidencias (caso típico del
  /// operador en campo), ve solo esas acciones acotadas.
  Widget _buildActionButtons() {
    final usuario = Provider.of<AuthProvider>(context).usuario;
    final puedeEditar =
        usuario?.tienePermiso(PermissionConstants.editarRecogidas) ?? false;
    final puedeCambiarEstado =
        usuario?.tienePermiso(PermissionConstants.cambiarEstadoRecogidas) ??
        false;
    final puedeSubirEvidencias =
        usuario?.tienePermiso(PermissionConstants.subirEvidencias) ?? false;

    final botones = <Widget>[];

    if (puedeEditar) {
      botones.addAll([
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _editarRecogida,
            icon: const Icon(Icons.edit),
            label: const Text('Editar Recogida'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _agregarEvidencia,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Agregar Evidencia'),
          ),
        ),
      ]);
    } else if (puedeCambiarEstado || puedeSubirEvidencias) {
      botones.addAll([
        if (puedeCambiarEstado)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cambiarEstado,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Cambiar estado y evidencia'),
            ),
          ),
        if (puedeCambiarEstado && puedeSubirEvidencias)
          const SizedBox(height: 12),
        if (puedeSubirEvidencias)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _agregarEvidencia,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Agregar Evidencia'),
            ),
          ),
      ]);
    }

    botones.addAll([
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.timeline),
          label: const Text('Ver Historial de Estados'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    HistorialEstadosScreen(recogidaId: _recogida.id),
              ),
            );
          },
        ),
      ),
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: botones,
    );
  }
}
