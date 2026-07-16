import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cierre_caja.dart';
import '../providers/ingresos_provider.dart';
import '../themes/app_theme.dart';

/// Pantalla para que el administrador cierre la caja de un operador o
/// subadministrador: elige a quién, ve cuánto tiene pendiente (desglosado
/// por efectivo/transferencia, con el detalle de cada cliente) y confirma.
class CerrarCajaScreen extends StatefulWidget {
  const CerrarCajaScreen({super.key});

  @override
  State<CerrarCajaScreen> createState() => _CerrarCajaScreenState();
}

/// Estado de [CerrarCajaScreen]: maneja la carga de operadores/subadmins
/// disponibles, el resumen de caja del seleccionado y la confirmación del
/// cierre.
class _CerrarCajaScreenState extends State<CerrarCajaScreen> {
  final _observacionesController = TextEditingController();
  final _formatoMoneda = NumberFormat.currency();

  List<OperadorDisponible> _operadores = [];
  OperadorDisponible? _seleccionado;
  ResumenCaja? _resumen;

  bool _cargandoOperadores = true;
  bool _cargandoResumen = false;
  bool _cerrando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarOperadores();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  /// Carga la lista de operadores y subadministradores que tienen ingresos
  /// pendientes de cerrar, y preselecciona automáticamente el primero para
  /// no dejar la pantalla vacía.
  Future<void> _cargarOperadores() async {
    setState(() {
      _cargandoOperadores = true;
      _error = null;
    });

    try {
      final provider = Provider.of<IngresosProvider>(context, listen: false);
      final operadores = await provider.obtenerOperadoresDisponibles();
      if (!mounted) return;
      setState(() {
        _operadores = operadores;
        _cargandoOperadores = false;
      });
      if (operadores.isNotEmpty) {
        await _seleccionarOperador(operadores.first);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoOperadores = false;
        _error = 'No se pudieron cargar los operadores';
      });
    }
  }

  /// Pide al backend el resumen de caja pendiente del operador elegido
  /// (total, desglose efectivo/transferencia y detalle por cliente).
  Future<void> _seleccionarOperador(OperadorDisponible operador) async {
    setState(() {
      _seleccionado = operador;
      _resumen = null;
      _cargandoResumen = true;
      _error = null;
    });

    try {
      final provider = Provider.of<IngresosProvider>(context, listen: false);
      final resumen = await provider.resumenCaja(operador.id);
      if (!mounted) return;
      setState(() {
        _resumen = resumen;
        _cargandoResumen = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoResumen = false;
        _error = 'No se pudo cargar el resumen de este operador';
      });
    }
  }

  /// Confirma el cierre de caja del operador seleccionado: el backend marca
  /// como cerrados todos sus ingresos pendientes hasta ese momento. Requiere
  /// el permiso `cerrarCaja`.
  Future<void> _cerrarCaja() async {
    final operador = _seleccionado;
    if (operador == null) return;

    setState(() => _cerrando = true);

    try {
      final provider = Provider.of<IngresosProvider>(context, listen: false);
      final cierre = await provider.cerrarCaja(
        operador.id,
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, cierre);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _cerrando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cerrar caja')),
      body: _cargandoOperadores
          ? const Center(child: CircularProgressIndicator())
          : _operadores.isEmpty
          ? const Center(child: Text('No hay operadores ni subadministradores registrados.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _seleccionado?.id,
                    decoration: const InputDecoration(
                      labelText: 'Operador o subadministrador',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    items: _operadores
                        .map(
                          (o) => DropdownMenuItem(
                            value: o.id,
                            child: Text('${o.nombre} (${o.rol})'),
                          ),
                        )
                        .toList(),
                    onChanged: _cerrando
                        ? null
                        : (id) {
                            final operador = _operadores.firstWhere((o) => o.id == id);
                            _seleccionarOperador(operador);
                          },
                  ),
                  const SizedBox(height: 20),
                  if (_cargandoResumen)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(_error!, style: const TextStyle(color: LoginovaColors.error)),
                    )
                  else if (_resumen != null)
                    _buildResumen(_resumen!),
                ],
              ),
            ),
    );
  }

  Widget _buildResumen(ResumenCaja resumen) {
    if (resumen.count == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Este operador no tiene dinero pendiente por cerrar.'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: LoginovaColors.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total pendiente',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  _formatoMoneda.format(resumen.total),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: LoginovaColors.primary,
                  ),
                ),
                Text('${resumen.count} movimiento(s)'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTotalCard(
                'Efectivo',
                resumen.totalEfectivo,
                Icons.payments,
                LoginovaColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTotalCard(
                'Transferencia',
                resumen.totalTransferencia,
                Icons.account_balance,
                LoginovaColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Detalle', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...resumen.detalle.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item.clienteNombre.isEmpty ? 'Cliente' : item.clienteNombre),
              subtitle: Text(_formatearFecha(item.fechaIngreso)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatoMoneda.format(item.monto),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(item.formaPago, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _observacionesController,
          enabled: !_cerrando,
          decoration: const InputDecoration(
            labelText: 'Observaciones (opcional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _cerrando ? null : _cerrarCaja,
          icon: _cerrando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.lock_clock),
          label: Text(_cerrando ? 'Cerrando...' : 'Cerrar caja'),
        ),
      ],
    );
  }

  Widget _buildTotalCard(String titulo, double monto, IconData icono, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 18, color: color),
                const SizedBox(width: 6),
                Text(titulo, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatoMoneda.format(monto),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final local = fecha.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

/// Formateador de moneda simple (sin dependencias extra de intl para
/// mantener el paquete liviano).
class NumberFormat {
  NumberFormat.currency();

  String format(double valor) {
    final entero = valor.round();
    final texto = entero.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < texto.length; i++) {
      if (i > 0 && (texto.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(texto[i]);
    }
    return '${entero < 0 ? '-' : ''}\$$buffer';
  }
}
