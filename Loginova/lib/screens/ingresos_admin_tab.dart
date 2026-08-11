import 'package:flutter/material.dart';

import 'cerrar_caja_screen.dart';
import 'resultados_ingresos_screen.dart';

/// Panel de ingresos para administradores: arma los filtros de búsqueda
/// (cliente, operador y/o rango de fechas — puede buscarse solo con
/// fechas, dejando cliente/operador vacíos) y, al presionar "Buscar",
/// siempre abre una pantalla nueva ([ResultadosIngresosScreen]) con el
/// resumen, los gráficos y el detalle de movimientos para ese filtro. Esa
/// pantalla de resultados tiene su propio botón "Salir" que regresa aquí.
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
  void dispose() {
    _clienteController.dispose();
    _operadorController.dispose();
    super.dispose();
  }

  /// Abre el selector de fecha para el filtro "desde" o "hasta". No busca
  /// de inmediato: la búsqueda solo se dispara al presionar "Buscar", para
  /// poder combinar fecha con cliente/operador (o dejarlos vacíos y buscar
  /// solo por fecha) antes de navegar a los resultados.
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
  }

  /// Valida el rango de fechas (si se eligieron ambas) y abre la pantalla
  /// de resultados con los filtros actuales. Si no se llenó ningún campo,
  /// muestra todos los ingresos.
  void _buscar() {
    if (_fechaDesde != null &&
        _fechaHasta != null &&
        _fechaHasta!.isBefore(_fechaDesde!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha "hasta" no puede ser anterior a "desde"'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadosIngresosScreen(
          cliente: _clienteController.text,
          operador: _operadorController.text,
          fechaDesde: _fechaDesde,
          fechaHasta: _fechaHasta,
        ),
      ),
    );
  }

  void _limpiarFiltros() {
    _clienteController.clear();
    _operadorController.clear();
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
    });
  }

  Future<void> _abrirCerrarCaja() async {
    final cierre = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CerrarCajaScreen()),
    );

    // CerrarCajaScreen no muestra su propia confirmación de éxito (solo un
    // snackbar de error si falla): el llamador es quien debe confirmarle al
    // admin que la caja sí se cerró, o de lo contrario cerrar una caja (una
    // acción financiera/de auditoría) no da ninguna señal visible de éxito.
    if (cierre != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caja cerrada correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buscar ingresos',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Puedes buscar solo por fecha, dejando cliente y operador vacíos.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _clienteController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por cliente (opcional)',
                    prefixIcon: Icon(Icons.person_search),
                  ),
                  onSubmitted: (_) => _buscar(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _operadorController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por operador responsable (opcional)',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  onSubmitted: (_) => _buscar(),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _buscar,
                        icon: const Icon(Icons.search),
                        label: const Text('Buscar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _limpiarFiltros,
                        icon: const Icon(Icons.clear),
                        label: const Text('Limpiar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cierre de caja',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _abrirCerrarCaja,
                    icon: const Icon(Icons.lock_clock),
                    label: const Text('Cerrar caja'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
