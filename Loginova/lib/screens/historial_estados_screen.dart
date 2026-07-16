import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../themes/app_theme.dart';
import '../widgets/menu_drawer.dart';

/// Pantalla que lista el historial de cambios de estado de las recogidas
/// (auditoría de quién movió cada recogida entre Pendiente/Recogida/Cancelada
/// y cuándo). Si [recogidaId] viene informado muestra solo el historial de
/// esa recogida (usada embebida en el detalle); si es null, muestra el
/// historial global desde el menú.
class HistorialEstadosScreen extends StatefulWidget {
  final int? recogidaId;

  const HistorialEstadosScreen({super.key, this.recogidaId});

  @override
  State<HistorialEstadosScreen> createState() => _HistorialEstadosScreenState();
}

class _HistorialEstadosScreenState extends State<HistorialEstadosScreen> {
  final List<Map<String, dynamic>> _historial = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  /// Trae del backend el historial de estados: global (`/historialestados`)
  /// o filtrado por una recogida específica si [HistorialEstadosScreen.recogidaId]
  /// no es nulo.
  Future<void> _cargarHistorial() async {
    setState(() => _cargando = true);

    final path = widget.recogidaId == null
        ? '/historialestados'
        : '/historialestados/recogida/${widget.recogidaId}';

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$path'),
        headers: ApiService.jsonHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final parsed = data
            .whereType<Map<String, dynamic>>()
            .map((h) => Map<String, dynamic>.from(h))
            .toList();

        if (!mounted) return;
        setState(() {
          _historial
            ..clear()
            ..addAll(parsed);
        });
      } else {
        _showMessage('No se pudo cargar el historial de estados');
      }
    } catch (_) {
      _showMessage('Error de red cargando historial');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Formatea una fecha ISO (tal como llega del backend en UTC) a hora local
  /// legible dd/mm/yyyy hh:mm.
  String _fecha(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'Sin fecha';
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.recogidaId == null
          ? const MenuDrawer(currentRoute: '/historial-estados')
          : null,
      appBar: AppBar(
        title: Text(
          widget.recogidaId == null
              ? 'Historial de Estados'
              : 'Historial Recogida #${widget.recogidaId}',
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarHistorial,
              child: _historial.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 120),
                        Center(
                          child: Text('No hay cambios de estado registrados'),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _historial.length,
                      itemBuilder: (context, index) {
                        final item = _historial[index];
                        final estadoAnterior = (item['estadoAnterior'] ?? 'N/A')
                            .toString();
                        final estadoNuevo = (item['estadoNuevo'] ?? 'N/A')
                            .toString();
                        final usuarioId = (item['usuarioId'] ?? '-').toString();

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.timeline),
                            title: Text(
                              'Recogida #${item['recogidaId'] ?? '-'}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Cambio: $estadoAnterior -> $estadoNuevo'),
                                const SizedBox(height: 4),
                                Text('Usuario ID: $usuarioId'),
                                const SizedBox(height: 4),
                                Text(
                                  _fecha(item['fechaCambio']),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: LoginovaColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                estadoNuevo,
                                style: const TextStyle(
                                  color: LoginovaColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
