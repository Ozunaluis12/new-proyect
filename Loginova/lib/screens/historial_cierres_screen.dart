import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cierre_caja.dart';
import '../providers/ingresos_provider.dart';
import '../themes/app_theme.dart';
import '../widgets/menu_drawer.dart';

/// Historial de todos los cierres de caja (manuales y automáticos), con
/// acceso al detalle de cada uno.
class HistorialCierresScreen extends StatefulWidget {
  const HistorialCierresScreen({super.key});

  @override
  State<HistorialCierresScreen> createState() => _HistorialCierresScreenState();
}

class _HistorialCierresScreenState extends State<HistorialCierresScreen> {
  List<CierreCaja> _cierres = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Carga la lista completa de cierres de caja (manuales y los generados
  /// automáticamente por el backend a las 11:59pm hora Colombia).
  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final provider = Provider.of<IngresosProvider>(context, listen: false);
      final cierres = await provider.obtenerHistorialCierres();
      if (!mounted) return;
      setState(() {
        _cierres = cierres;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el historial';
        _cargando = false;
      });
    }
  }

  /// Pide al backend el detalle completo de un cierre puntual (incluye el
  /// desglose por cliente/forma de pago, que no viene en el listado) y lo
  /// muestra en una hoja inferior.
  Future<void> _abrirDetalle(CierreCaja cierre) async {
    final provider = Provider.of<IngresosProvider>(context, listen: false);
    try {
      final detalle = await provider.obtenerDetalleCierre(cierre.id);
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => _DetalleCierreSheet(cierre: detalle),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo cargar el detalle')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MenuDrawer(currentRoute: '/historial-cierres'),
      appBar: AppBar(title: const Text('Historial de cierres de caja')),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : _cierres.isEmpty
            ? const Center(child: Text('Todavía no hay cierres de caja registrados.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _cierres.length,
                itemBuilder: (context, index) {
                  final cierre = _cierres[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () => _abrirDetalle(cierre),
                      leading: CircleAvatar(
                        backgroundColor: cierre.generadoAutomaticamente
                            ? LoginovaColors.warning.withValues(alpha: 0.15)
                            : LoginovaColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          cierre.generadoAutomaticamente ? Icons.schedule : Icons.person,
                          color: cierre.generadoAutomaticamente
                              ? LoginovaColors.warning
                              : LoginovaColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(cierre.operadorNombre),
                      subtitle: Text(
                        '${_formatearFecha(cierre.fechaCreacion)}'
                        '${cierre.generadoAutomaticamente ? ' · Automático' : ''}',
                      ),
                      trailing: Text(
                        _formatoMoneda.format(cierre.montoTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

String _formatearFecha(DateTime fecha) {
  final local = fecha.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

final _formatoMoneda = _NumberFormatSimple();

class _NumberFormatSimple {
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

/// Hoja inferior (bottom sheet) con el detalle de un cierre de caja puntual:
/// totales desglosados por efectivo/transferencia y el listado de
/// movimientos que lo componen.
class _DetalleCierreSheet extends StatelessWidget {
  final CierreCaja cierre;

  const _DetalleCierreSheet({required this.cierre});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cierre.operadorNombre, style: Theme.of(context).textTheme.headlineSmall),
            Text(
              _formatearFecha(cierre.fechaCreacion),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _resumenItem('Total', cierre.montoTotal, LoginovaColors.primary),
                _resumenItem('Efectivo', cierre.montoEfectivo, LoginovaColors.success),
                _resumenItem('Transferencia', cierre.montoTransferencia, LoginovaColors.info),
              ],
            ),
            if ((cierre.observaciones ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Observaciones: ${cierre.observaciones}'),
            ],
            const SizedBox(height: 16),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: (cierre.detalle ?? [])
                    .map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.clienteNombre.isEmpty ? 'Cliente' : item.clienteNombre),
                        subtitle: Text(item.formaPago),
                        trailing: Text(_formatoMoneda.format(item.monto)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenItem(String label, double valor, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          _formatoMoneda.format(valor),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
