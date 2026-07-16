import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../themes/app_theme.dart';
import '../widgets/menu_drawer.dart';

/// Pantalla que lista las notificaciones del usuario autenticado (avisos
/// del sistema, p. ej. recogidas asignadas o cambios de estado), con
/// búsqueda, filtro de no leídas, paginación local y un botón para probar
/// el envío de notificaciones.
class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final List<Map<String, dynamic>> _notificaciones = [];
  bool _cargando = true;
  bool _enviandoPrueba = false;
  bool _soloNoLeidas = false;
  String _busqueda = '';
  // Cantidad de notificaciones visibles en la lista; crece de 20 en 20 con
  // "Cargar más" en vez de paginar contra el backend.
  int _visibleCount = 20;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  /// Trae todas las notificaciones del usuario logueado desde el backend.
  Future<void> _cargarNotificaciones() async {
    setState(() => _cargando = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/notificaciones/mis-notificaciones'),
        headers: ApiService.jsonHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final parsed = data
            .whereType<Map<String, dynamic>>()
            .map((n) => Map<String, dynamic>.from(n))
            .toList();

        if (!mounted) return;
        setState(() {
          _notificaciones
            ..clear()
            ..addAll(parsed);
          _visibleCount = 20;
        });
      } else {
        _mostrarSnackBar('No se pudieron cargar las notificaciones');
      }
    } catch (_) {
      _mostrarSnackBar('Error de red al cargar notificaciones');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  /// Marca una notificación como leída en el backend y actualiza el estado
  /// local sin recargar toda la lista.
  Future<void> _marcarComoLeida(int id) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/notificaciones/$id/marcar-leida'),
        headers: ApiService.jsonHeaders,
      );

      if (response.statusCode == 204) {
        if (!mounted) return;
        setState(() {
          final index = _notificaciones.indexWhere(
            (n) => _intValue(n['id']) == id,
          );
          if (index >= 0) {
            _notificaciones[index]['leido'] = true;
          }
        });
        return;
      }

      _mostrarSnackBar('No fue posible marcar la notificación');
    } catch (_) {
      _mostrarSnackBar('Error de red al actualizar notificación');
    }
  }

  /// Pide al backend que envíe una notificación de prueba al usuario actual
  /// (botón de diagnóstico) y refresca la lista si tuvo éxito.
  Future<void> _enviarPrueba() async {
    if (_enviandoPrueba) return;

    setState(() => _enviandoPrueba = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/notificaciones/test'),
        headers: ApiService.jsonHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _mostrarSnackBar('Notificación de prueba enviada');
        await _cargarNotificaciones();
      } else {
        _mostrarSnackBar('No se pudo enviar la notificación de prueba');
      }
    } catch (_) {
      _mostrarSnackBar('Error de red enviando notificación de prueba');
    } finally {
      if (mounted) {
        setState(() => _enviandoPrueba = false);
      }
    }
  }

  /// Convierte el valor crudo del JSON (puede llegar como int o String) a
  /// un entero seguro.
  int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Convierte el valor crudo del JSON (bool, String "true"/"false" o
  /// número 0/1) a un booleano seguro.
  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value == 1;
    return false;
  }

  /// Formatea una fecha ISO del backend a hora local legible dd/mm/yyyy hh:mm.
  String _fechaTexto(dynamic value) {
    if (value == null) return 'Sin fecha';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return 'Sin fecha';
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  void _mostrarSnackBar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _notificaciones.where((n) {
      final leido = _boolValue(n['leido']);
      final titulo = (n['titulo'] ?? '').toString().toLowerCase();
      final cuerpo = (n['cuerpo'] ?? '').toString().toLowerCase();
      final query = _busqueda.trim().toLowerCase();

      if (_soloNoLeidas && leido) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return titulo.contains(query) || cuerpo.contains(query);
    }).toList();

    final visibles = filtradas.take(_visibleCount).toList();
    final puedeCargarMas = filtradas.length > _visibleCount;

    return Scaffold(
      drawer: const MenuDrawer(currentRoute: '/notificaciones'),
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: _enviandoPrueba
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            tooltip: 'Enviar prueba',
            onPressed: _enviandoPrueba ? null : _enviarPrueba,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : filtradas.isEmpty
          ? const Center(
              child: Text('No hay notificaciones para el filtro actual'),
            )
          : RefreshIndicator(
              onRefresh: _cargarNotificaciones,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Buscar por título o cuerpo',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _busqueda = value;
                        _visibleCount = 20;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _soloNoLeidas,
                    title: const Text('Mostrar solo no leídas'),
                    onChanged: (value) {
                      setState(() {
                        _soloNoLeidas = value;
                        _visibleCount = 20;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  ...visibles.map((notificacion) {
                    final leido = _boolValue(notificacion['leido']);
                    final id = _intValue(notificacion['id']);

                    return Card(
                      color: leido
                          ? null
                          : LoginovaColors.info.withValues(alpha: 0.08),
                      child: ListTile(
                        leading: Icon(
                          leido
                              ? Icons.mark_email_read
                              : Icons.mark_email_unread,
                          color: leido
                              ? LoginovaColors.textSecondary
                              : LoginovaColors.primary,
                        ),
                        title: Text(
                          (notificacion['titulo'] ?? 'Sin título').toString(),
                          style: TextStyle(
                            fontWeight: leido
                                ? FontWeight.w500
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text((notificacion['cuerpo'] ?? '').toString()),
                            const SizedBox(height: 6),
                            Text(
                              _fechaTexto(notificacion['fechaCreacion']),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: leido
                            ? null
                            : TextButton(
                                onPressed: () => _marcarComoLeida(id),
                                child: const Text('Marcar leída'),
                              ),
                      ),
                    );
                  }),
                  if (puedeCargarMas)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
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
                    ),
                ],
              ),
            ),
    );
  }
}
