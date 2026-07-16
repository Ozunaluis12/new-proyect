import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/ingreso.dart';
import '../providers/ingresos_provider.dart';
import '../themes/app_theme.dart';
import 'cerrar_caja_screen.dart';

class _ResumenMonto {
  final String nombre;
  final double total;

  const _ResumenMonto({required this.nombre, required this.total});
}

class IngresosAdminTab extends StatefulWidget {
  const IngresosAdminTab({super.key});

  @override
  State<IngresosAdminTab> createState() => _IngresosAdminTabState();
}

class _IngresosAdminTabState extends State<IngresosAdminTab> {
  final _clienteController = TextEditingController();
  final _operadorController = TextEditingController();
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IngresosProvider>(context, listen: false).cargarIngresos();
    });
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _operadorController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    await Provider.of<IngresosProvider>(context, listen: false).cargarIngresos(
      cliente: _clienteController.text,
      operador: _operadorController.text,
      fechaDesde: _fechaDesde,
      fechaHasta: _fechaHasta,
    );
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final inicial = esDesde
        ? (_fechaDesde ?? DateTime.now())
        : (_fechaHasta ?? DateTime.now());
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (fecha == null) return;
    setState(() {
      if (esDesde) {
        _fechaDesde = fecha;
      } else {
        _fechaHasta = fecha;
      }
    });
    await _cargar();
  }

  Future<void> _exportarCsv() async {
    final provider = Provider.of<IngresosProvider>(context, listen: false);
    try {
      final bytes = await provider.exportarIngresosCsv(
        cliente: _clienteController.text,
        operador: _operadorController.text,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      );

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/ingresos_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Exportación de ingresos');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exportando CSV: $e')));
    }
  }

  Future<void> _abrirCerrarCaja() async {
    final cierre = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CerrarCajaScreen()),
    );

    if (cierre != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Caja cerrada correctamente')));
      await _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IngresosProvider>(
      builder: (context, provider, _) {
        final ingresos = provider.ingresos;
        final total = ingresos.fold<double>(0, (sum, item) => sum + item.monto);
        final promedio = ingresos.isEmpty ? 0.0 : total / ingresos.length;
        final ingresoMayor = ingresos.isEmpty
            ? null
            : ingresos.reduce(
                (actual, siguiente) =>
                    actual.monto >= siguiente.monto ? actual : siguiente,
              );
        final topClientes = _agruparTotales(
          ingresos,
          (ingreso) => ingreso.clienteNombre,
        );
        final topOperadores = _agruparTotales(
          ingresos,
          (ingreso) => ingreso.responsableNombre,
        );
        final totalesPorFormaPago = _agruparTotales(
          ingresos,
          (ingreso) => ingreso.formaPago,
        );
        final totalesPorDia = _agruparTotales(
          ingresos,
          (ingreso) => _formatearFecha(ingreso.fechaIngreso),
        );

        return RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFiltros(),
              const SizedBox(height: 16),
              _buildResumenPrincipal(
                total: total,
                cantidadRegistros: ingresos.length,
                promedio: promedio,
                ingresoMayor: ingresoMayor,
                mejorCliente: topClientes.isEmpty ? null : topClientes.first,
                mejorOperador: topOperadores.isEmpty
                    ? null
                    : topOperadores.first,
              ),
              const SizedBox(height: 16),
              if (provider.cargando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (ingresos.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No hay ingresos registrados con los filtros actuales.',
                    ),
                  ),
                )
              else ...[
                _buildVisualCharts(
                  topClientes: topClientes.take(5).toList(),
                  topOperadores: topOperadores.take(5).toList(),
                  totalesPorFormaPago: totalesPorFormaPago,
                  totalesPorDia: totalesPorDia.take(7).toList(),
                ),
                const SizedBox(height: 16),
                _buildResumenPorCategoria(
                  titulo: 'Totales por forma de pago',
                  icono: Icons.account_balance_wallet,
                  items: totalesPorFormaPago,
                ),
                const SizedBox(height: 16),
                _buildResumenPorCategoria(
                  titulo: 'Top clientes',
                  icono: Icons.business,
                  items: topClientes.take(5).toList(),
                ),
                const SizedBox(height: 16),
                _buildResumenPorCategoria(
                  titulo: 'Top operadores responsables',
                  icono: Icons.badge,
                  items: topOperadores.take(5).toList(),
                ),
                const SizedBox(height: 16),
                _buildResumenPorCategoria(
                  titulo: 'Ingresos por día',
                  icono: Icons.calendar_month,
                  items: totalesPorDia.take(7).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Detalle de movimientos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...ingresos.map(_buildIngresoCard),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildResumenPrincipal({
    required double total,
    required int cantidadRegistros,
    required double promedio,
    required Ingreso? ingresoMayor,
    required _ResumenMonto? mejorCliente,
    required _ResumenMonto? mejorOperador,
  }) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _buildMetricCard(
              titulo: 'Total ingresado',
              valor: '\$${total.toStringAsFixed(2)}',
              subtitulo: '$cantidadRegistros registros',
              icono: Icons.payments,
              color: LoginovaColors.success,
            ),
            _buildMetricCard(
              titulo: 'Promedio por ingreso',
              valor: '\$${promedio.toStringAsFixed(2)}',
              subtitulo: 'Media actual',
              icono: Icons.analytics,
              color: LoginovaColors.primary,
            ),
            _buildMetricCard(
              titulo: 'Ingreso más alto',
              valor: ingresoMayor == null
                  ? '\$0.00'
                  : '\$${ingresoMayor.monto.toStringAsFixed(2)}',
              subtitulo: ingresoMayor?.clienteNombre ?? 'Sin datos',
              icono: Icons.trending_up,
              color: LoginovaColors.secondary,
            ),
            _buildMetricCard(
              titulo: 'Mejor operador',
              valor: mejorOperador == null
                  ? '\$0.00'
                  : '\$${mejorOperador.total.toStringAsFixed(2)}',
              subtitulo: mejorOperador?.nombre ?? 'Sin datos',
              icono: Icons.emoji_events,
              color: LoginovaColors.info,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.groups, color: LoginovaColors.primary),
            title: const Text('Cliente con más ingresos'),
            subtitle: Text(mejorCliente?.nombre ?? 'Sin datos'),
            trailing: Text(
              mejorCliente == null
                  ? '\$0.00'
                  : '\$${mejorCliente.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: LoginovaColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualCharts({
    required List<_ResumenMonto> topClientes,
    required List<_ResumenMonto> topOperadores,
    required List<_ResumenMonto> totalesPorFormaPago,
    required List<_ResumenMonto> totalesPorDia,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gráficos visuales',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildBarChartCard(
          titulo: 'Clientes con más ingresos',
          icono: Icons.business_center,
          color: LoginovaColors.secondary,
          items: topClientes,
        ),
        const SizedBox(height: 12),
        _buildBarChartCard(
          titulo: 'Operadores con más ingresos',
          icono: Icons.badge,
          color: LoginovaColors.primary,
          items: topOperadores,
        ),
        const SizedBox(height: 12),
        _buildPaymentDistributionCard(totalesPorFormaPago),
        const SizedBox(height: 12),
        _buildDailyTrendCard(totalesPorDia),
      ],
    );
  }

  Widget _buildMetricCard({
    required String titulo,
    required String valor,
    required String subtitulo,
    required IconData icono,
    required Color color,
  }) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icono, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(subtitulo, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard({
    required String titulo,
    required IconData icono,
    required Color color,
    required List<_ResumenMonto> items,
  }) {
    final maximo = items.isEmpty
        ? 1.0
        : items.map((item) => item.total).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: color),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Text('Sin datos para mostrar')
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${item.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: item.total / maximo,
                          minHeight: 10,
                          backgroundColor: color.withValues(alpha: 0.14),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDistributionCard(List<_ResumenMonto> items) {
    final total = items.fold<double>(0, (sum, item) => sum + item.total);
    final colores = [
      LoginovaColors.success,
      LoginovaColors.info,
      LoginovaColors.secondary,
      LoginovaColors.primary,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: LoginovaColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  'Distribución por forma de pago',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Text('Sin datos para mostrar')
            else ...[
              Row(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final flex = total == 0
                      ? 1
                      : (item.total * 1000 ~/ total).clamp(1, 1000);
                  return Expanded(
                    flex: flex,
                    child: Container(
                      height: 18,
                      margin: EdgeInsets.only(
                        right: index == items.length - 1 ? 0 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: colores[index % colores.length],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final porcentaje = total == 0
                    ? 0.0
                    : (item.total / total) * 100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colores[index % colores.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item.nombre)),
                      Text(
                        '${porcentaje.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '\$${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: LoginovaColors.success,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTrendCard(List<_ResumenMonto> items) {
    final maximo = items.isEmpty
        ? 1.0
        : items.map((item) => item.total).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: LoginovaColors.info),
                const SizedBox(width: 8),
                Text(
                  'Tendencia diaria',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Text('Sin datos para mostrar')
            else
              SizedBox(
                height: 190,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: items.reversed.map((item) {
                    final altura = (item.total / maximo) * 110;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '\$${item.total.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: altura.clamp(14, 110),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    LoginovaColors.info,
                                    LoginovaColors.primary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.nombre,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenPorCategoria({
    required String titulo,
    required IconData icono,
    required List<_ResumenMonto> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: LoginovaColors.primary),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('Sin datos para mostrar')
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.nombre)),
                      const SizedBox(width: 12),
                      Text(
                        '\$${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: LoginovaColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros de búsqueda',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _clienteController,
              decoration: const InputDecoration(
                labelText: 'Buscar por cliente',
                prefixIcon: Icon(Icons.person_search),
              ),
              onSubmitted: (_) => _cargar(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _operadorController,
              decoration: const InputDecoration(
                labelText: 'Buscar por operador responsable',
                prefixIcon: Icon(Icons.badge),
              ),
              onSubmitted: (_) => _cargar(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _seleccionarFecha(true),
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _fechaDesde == null
                          ? 'Fecha desde'
                          : '${_fechaDesde!.day}/${_fechaDesde!.month}/${_fechaDesde!.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _seleccionarFecha(false),
                    icon: const Icon(Icons.event),
                    label: Text(
                      _fechaHasta == null
                          ? 'Fecha hasta'
                          : '${_fechaHasta!.day}/${_fechaHasta!.month}/${_fechaHasta!.year}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _cargar,
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      _clienteController.clear();
                      _operadorController.clear();
                      setState(() {
                        _fechaDesde = null;
                        _fechaHasta = null;
                      });
                      await _cargar();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportarCsv,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Exportar CSV'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _abrirCerrarCaja,
                    icon: const Icon(Icons.lock_clock),
                    label: const Text('Cerrar caja'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngresoCard(Ingreso ingreso) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ingreso.clienteNombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '\$${ingreso.monto.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: LoginovaColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Responsable: ${ingreso.responsableNombre}'),
            Text('Forma de pago: ${ingreso.formaPago}'),
            Text('Recogida: #${ingreso.recogidaId}'),
            Text(
              'Fecha: ${ingreso.fechaIngreso.day}/${ingreso.fechaIngreso.month}/${ingreso.fechaIngreso.year}',
            ),
          ],
        ),
      ),
    );
  }

  List<_ResumenMonto> _agruparTotales(
    List<Ingreso> ingresos,
    String Function(Ingreso ingreso) selector,
  ) {
    final acumulado = <String, double>{};

    for (final ingreso in ingresos) {
      final clave = selector(ingreso).trim().isEmpty
          ? 'Sin dato'
          : selector(ingreso).trim();
      acumulado.update(
        clave,
        (valor) => valor + ingreso.monto,
        ifAbsent: () => ingreso.monto,
      );
    }

    final items = acumulado.entries
        .map((entry) => _ResumenMonto(nombre: entry.key, total: entry.value))
        .toList();

    items.sort((a, b) => b.total.compareTo(a.total));
    return items;
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}
