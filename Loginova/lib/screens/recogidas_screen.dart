import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/permission_constants.dart';
import '../models/recogida.dart';
import '../providers/auth_provider.dart';
import '../providers/recogida_provider.dart';
import '../themes/app_theme.dart';
import '../widgets/menu_drawer.dart';
import 'crear_recogida_screen.dart';
import 'cambiar_estado_recogida_screen.dart';
import 'detalle_recogida_screen.dart';
import 'editar_recogida_screen.dart';

/// Pantalla profesional que muestra la lista de recogidas con filtros y opciones.
class RecogidasScreen extends StatefulWidget {
  const RecogidasScreen({super.key});

  @override
  State<RecogidasScreen> createState() => _RecogidasScreenState();
}

class _RecogidasScreenState extends State<RecogidasScreen> {
  String _filtroEstado = 'Todos';
  final List<String> _estados = [
    'Todos',
    'Pendiente',
    'Asignada',
    'En Ruta',
    'Recogida',
    'Cancelada',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecogidaProvider>(context, listen: false).cargarRecogidas();
    });
  }

  Future<void> _abrirDetalle(Recogida recogida) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleRecogidaScreen(recogida: recogida),
      ),
    );

    if (!mounted) return;

    await Provider.of<RecogidaProvider>(
      context,
      listen: false,
    ).cargarRecogidas();
  }

  /// Filtra las recogidas según el estado seleccionado
  List<Recogida> _filtrarRecogidas(List<Recogida> recogidas) {
    if (_filtroEstado == 'Todos') {
      return recogidas;
    }
    return recogidas
        .where((r) => r.estado.toLowerCase() == _filtroEstado.toLowerCase())
        .toList();
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
    final usuario = Provider.of<AuthProvider>(context).usuario;
    final puedeCrearRecogidas =
        usuario?.tienePermiso(PermissionConstants.crearRecogidas) ?? false;

    return Scaffold(
      drawer: const MenuDrawer(currentRoute: '/recogidas'),
      appBar: AppBar(title: const Text('Recogidas'), elevation: 0),
      floatingActionButton: puedeCrearRecogidas
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CrearRecogidaScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Nueva'),
            )
          : null,
      body: Consumer<RecogidaProvider>(
        builder: (context, provider, _) {
          final recogidas = _filtrarRecogidas(provider.recogidas);

          return Column(
            children: [
              // Barra de filtros
              _buildFilterBar(),

              // Lista o estado vacío
              Expanded(
                child: provider.cargando
                    ? const Center(child: CircularProgressIndicator())
                    : recogidas.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: provider.cargarRecogidas,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          itemCount: recogidas.length,
                          itemBuilder: (context, index) {
                            final recogida = recogidas[index];
                            return _buildRecogidaCard(
                              context,
                              recogida,
                              provider,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Construye la barra de filtros
  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: _estados
            .map(
              (estado) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(estado),
                  selected: _filtroEstado == estado,
                  onSelected: (selected) {
                    setState(() => _filtroEstado = estado);
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  /// Construye la tarjeta de una recogida
  Widget _buildRecogidaCard(
    BuildContext context,
    Recogida recogida,
    RecogidaProvider provider,
  ) {
    final usuario = Provider.of<AuthProvider>(context).usuario;
    final puedeEditar =
        usuario?.tienePermiso(PermissionConstants.editarRecogidas) ?? false;
    final puedeCambiarEstado =
        usuario?.tienePermiso(PermissionConstants.cambiarEstadoRecogidas) ??
        false;

    final color = _getEstadoColor(recogida.estado);
    final icon = _getEstadoIcon(recogida.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _abrirDetalle(recogida),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con ID y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recogida #${recogida.id}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cliente ID: ${recogida.clienteId}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      border: Border.all(color: color),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: color, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          recogida.estado,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Información de paquetes
              Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 18,
                    color: LoginovaColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${recogida.cantidadPaquetes} paquetes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Observaciones
              if ((recogida.observaciones ?? '').isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.note,
                      size: 18,
                      color: LoginovaColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recogida.observaciones!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: LoginovaColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Botones de acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _abrirDetalle(recogida),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Ver'),
                  ),
                  const SizedBox(width: 8),
                  if (puedeEditar) ...[
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditarRecogidaScreen(recogida: recogida),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () =>
                          _showDeleteDialog(context, recogida.id, provider),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: LoginovaColors.error,
                      ),
                    ),
                  ] else if (puedeCambiarEstado) ...[
                    TextButton.icon(
                      onPressed: () async {
                        final actualizada = await Navigator.push<Recogida>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CambiarEstadoRecogidaScreen(recogida: recogida),
                          ),
                        );

                        if (actualizada != null && context.mounted) {
                          await provider.cargarRecogidas();
                        }
                      },
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Estado'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el estado vacío
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping,
            size: 64,
            color: LoginovaColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay recogidas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: LoginovaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea una nueva recogida para comenzar',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LoginovaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CrearRecogidaScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Crear Recogida'),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de confirmación para eliminar
  void _showDeleteDialog(
    BuildContext context,
    int recogidaId,
    RecogidaProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Recogida'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta recogida? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await provider.eliminarRecogida(recogidaId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recogida eliminada')),
                );
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo eliminar la recogida'),
                    backgroundColor: LoginovaColors.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: LoginovaColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
