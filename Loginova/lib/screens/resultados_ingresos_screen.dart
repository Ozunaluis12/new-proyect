import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/ingreso.dart';
import '../providers/ingresos_provider.dart';
import '../themes/app_theme.dart';

/// Total agregado de dinero para un agrupador (cliente, operador, forma de
/// pago o día), usado solo para alimentar las tarjetas/gráficos de esta
/// pantalla (no viene tal cual del backend, se calcula en [_agruparTotales]).
class _ResumenMonto {
  final String nombre;
  final double total;

  const _ResumenMonto({required this.nombre, required this.total});
}

/// Resultados de una búsqueda de ingresos: recibe los filtros ya elegidos
/// en el Panel de Ingresos (cliente, operador y/o rango de fechas — puede
/// buscarse solo con fechas, dejando cliente/operador vacíos) y muestra el
/// resumen, los gráficos y el detalle de movimientos para ese filtro. Se
/// abre siempre como una pantalla nueva al presionar "Buscar", con un botón
/// "Salir" explícito que regresa al Panel de Ingresos.
class ResultadosIngresosScreen extends StatefulWidget {
  final String? cliente;
  final String? operador;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  const ResultadosIngresosScreen({
    super.key,
    this.cliente,
    this.operador,
    this.fechaDesde,
    this.fechaHasta,
  });

  @override
  State<ResultadosIngresosScreen> createState() =>
      _ResultadosIngresosScreenState();
}

class _ResultadosIngresosScreenState extends State<ResultadosIngresosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    await Provider.of<IngresosProvider>(context, listen: false).cargarIngresos(
      cliente: widget.cliente,
      operador: widget.operador,
      fechaDesde: widget.fechaDesde,
      fechaHasta: widget.fechaHasta,
    );
  }

  /// Pide al backend el CSV de los ingresos con estos mismos filtros y abre
  /// el diálogo nativo de compartir/descargar. Usa XFile.fromData (bytes en
  /// memoria) en vez de escribir a un archivo temporal con path_provider:
  /// path_provider no tiene implementación para Flutter Web, así que
  /// escribir a disco fallaría ahí; XFile.fromData funciona igual en todas
  /// las plataformas (en web dispara la descarga del navegador).
  Future<void> _exportarCsv() async {
    final provider = Provider.of<IngresosProvider>(context, listen: false);
    try {
      final bytes = await provider.exportarIngresosCsv(
        cliente: widget.cliente,
        operador: widget.operador,
        fechaDesde: widget.fechaDesde,
        fechaHasta: widget.fechaHasta,
      );

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: 'ingresos_${DateTime.now().millisecondsSinceEpoch}.csv',
              mimeType: 'text/csv',
            ),
          ],
          text: 'Exportación de ingresos',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exportando CSV: $e')));
    }
  }

  /// Describe en una línea los filtros con los que se buscó, para que quede
  /// claro qué se está mostrando (p. ej. "Del 01/08/2026 al 15/08/2026").
  String _describirFiltros() {
    final partes = <String>[];
    if ((widget.cliente ?? '').trim().isNotEmpty) {
      partes.add('Cliente: ${widget.cliente!.trim()}');
    }
    if ((widget.operador ?? '').trim().isNotEmpty) {
      partes.add('Operador: ${widget.operador!.trim()}');
    }
    if (widget.fechaDesde != null) {
      partes.add('Desde: ${_formatearFecha(widget.fechaDesde!)}');
    }
    if (widget.fechaHasta != null) {
      partes.add('Hasta: ${_formatearFecha(widget.fechaHasta!)}');
    }
    return partes.isEmpty ? 'Todos los ingresos' : partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de ingresos'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _exportarCsv,
            icon: const Icon(Icons.file_download),
            tooltip: 'Exportar CSV',
          ),
        ],
      ),
      body: Consumer<IngresosProvider>(
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
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: LoginovaColors.primary.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt, color: LoginovaColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _describirFiltros(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (provider.cargando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (provider.error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: ${provider.error}'),
                    ),
                  )
                else if (ingresos.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No hay ingresos registrados con estos filtros.',
                      ),
                    ),
                  )
                else ...[
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Salir al panel de ingresos'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 700 ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: crossAxisCount >= 4 ? 1.3 : 1.45,
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
            );
          },
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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  titulo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
                      Expanded(
                        child: Text(
                          item.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${porcentaje.toStringAsFixed(1)}%',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '\$${item.total.toStringAsFixed(2)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: LoginovaColors.success,
                              ),
                            ),
                          ],
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

  Widget _buildIngresoCard(Ingreso ingreso) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ingreso.clienteNombre,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
            Text('Fecha: ${_formatearFecha(ingreso.fechaIngreso)}'),
          ],
        ),
      ),
    );
  }

  /// Agrupa una lista de ingresos sumando sus montos según la clave que
  /// devuelva [selector] (p. ej. cliente, operador, forma de pago o fecha),
  /// y devuelve el resultado ordenado de mayor a menor total. Es la base de
  /// todos los "top N" y gráficos de esta pantalla.
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

  /// Formatea una fecha como dd/mm/yyyy; se usa como clave de agrupación
  /// para el resumen "Ingresos por día" y para mostrar la fecha de cada
  /// movimiento.
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}
