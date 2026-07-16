import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../themes/app_theme.dart';
import '../widgets/menu_drawer.dart';

/// Pantalla de auditoría (solo Administrador): lista el historial de
/// operaciones CREATE/UPDATE/DELETE registradas por el backend sobre las
/// entidades del sistema (recogidas, usuarios, etc.), con filtro por acción
/// y búsqueda de texto.
class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  final List<Map<String, dynamic>> _logs = [];
  bool _cargando = true;
  String _filtroAccion = 'TODAS';
  String _busqueda = '';
  int _visibleCount = 20;

  @override
  void initState() {
    super.initState();
    _cargarAuditoria();
  }

  /// Pide el log de auditoría completo al backend. El endpoint solo lo
  /// puede leer un administrador, por eso se maneja explícitamente el 403
  /// (usuario autenticado pero sin rol suficiente) distinto de otros errores.
  Future<void> _cargarAuditoria() async {
    setState(() => _cargando = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/auditoria'),
        headers: ApiService.jsonHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final parsed = data
            .whereType<Map<String, dynamic>>()
            .map((l) => Map<String, dynamic>.from(l))
            .toList();

        if (!mounted) return;
        setState(() {
          _logs
            ..clear()
            ..addAll(parsed);
          _visibleCount = 20;
        });
      } else if (response.statusCode == 403) {
        _mostrarMensaje('Solo administradores pueden ver la auditoría');
      } else {
        _mostrarMensaje('No se pudo cargar la auditoría');
      }
    } catch (_) {
      _mostrarMensaje('Error de red cargando auditoría');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Aplica el filtro de acción (TODAS/CREATE/UPDATE/DELETE) y la búsqueda
  /// de texto sobre los logs ya cargados en memoria (sin volver a llamar al
  /// backend), para que la UI responda al instante.
  List<Map<String, dynamic>> get _logsFiltrados {
    final filteredByAction = _filtroAccion == 'TODAS'
        ? _logs
        : _logs
              .where(
                (l) =>
                    (l['accion'] ?? '').toString().toUpperCase() ==
                    _filtroAccion,
              )
              .toList();

    final query = _busqueda.trim().toLowerCase();
    if (query.isEmpty) {
      return filteredByAction;
    }

    return filteredByAction.where((l) {
      final entidad = (l['entidadTipo'] ?? '').toString().toLowerCase();
      final descripcion = (l['descripcion'] ?? '').toString().toLowerCase();
      final entidadId = (l['entidadId'] ?? '').toString().toLowerCase();
      return entidad.contains(query) ||
          descripcion.contains(query) ||
          entidadId.contains(query);
    }).toList();
  }

  String _fecha(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'Sin fecha';
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Color _colorAccion(String accion) {
    switch (accion.toUpperCase()) {
      case 'CREATE':
        return LoginovaColors.success;
      case 'UPDATE':
        return LoginovaColors.info;
      case 'DELETE':
        return LoginovaColors.error;
      default:
        return LoginovaColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Paginación simple en cliente: solo se muestran _visibleCount registros
    // y el botón "Cargar más" amplía ese límite de a 20.
    final logsVisibles = _logsFiltrados.take(_visibleCount).toList();
    final puedeCargarMas = _logsFiltrados.length > _visibleCount;

    final isAdmin =
        Provider.of<AuthProvider>(context).usuario?.rol.toLowerCase() ==
        'administrador';

    return Scaffold(
      drawer: const MenuDrawer(currentRoute: '/auditoria'),
      appBar: AppBar(title: const Text('Auditoría')),
      body: !isAdmin
          ? const Center(
              child: Text('Solo administradores pueden acceder a esta vista.'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Buscar por entidad, descripción o ID',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _busqueda = value;
                            _visibleCount = 20;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['TODAS', 'CREATE', 'UPDATE', 'DELETE']
                            .map(
                              (accion) => ChoiceChip(
                                label: Text(accion),
                                selected: _filtroAccion == accion,
                                onSelected: (_) {
                                  setState(() {
                                    _filtroAccion = accion;
                                    _visibleCount = 20;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _cargarAuditoria,
                          child: _logsFiltrados.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(height: 120),
                                    Center(
                                      child: Text('Sin registros de auditoría'),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  itemCount:
                                      logsVisibles.length +
                                      (puedeCargarMas ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (puedeCargarMas &&
                                        index == logsVisibles.length) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Center(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _visibleCount += 20;
                                              });
                                            },
                                            icon: const Icon(Icons.expand_more),
                                            label: const Text('Cargar más'),
                                          ),
                                        ),
                                      );
                                    }

                                    final log = logsVisibles[index];
                                    final accion = (log['accion'] ?? 'N/A')
                                        .toString();
                                    final color = _colorAccion(accion);

                                    return Card(
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: color.withValues(
                                            alpha: 0.15,
                                          ),
                                          child: Icon(
                                            Icons.fact_check,
                                            color: color,
                                          ),
                                        ),
                                        title: Text(
                                          '${(log['entidadTipo'] ?? 'Entidad').toString()} #${(log['entidadId'] ?? '-').toString()}',
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              (log['descripcion'] ??
                                                      'Sin descripción')
                                                  .toString(),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _fecha(log['fechaCambio']),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            accion,
                                            style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
    );
  }
}
