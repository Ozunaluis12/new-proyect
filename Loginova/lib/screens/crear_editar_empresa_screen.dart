import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/empresa_cliente.dart';
import '../providers/empresas_clientes_provider.dart';
import '../themes/app_theme.dart';

/// Formulario para registrar o editar una empresa cliente del CRM interno
/// de soporte (fechas de membresía, contacto, notas de seguimiento).
class CrearEditarEmpresaScreen extends StatefulWidget {
  /// Si viene null, es creación; si trae una empresa, es edición.
  final EmpresaCliente? empresa;

  const CrearEditarEmpresaScreen({super.key, this.empresa});

  @override
  State<CrearEditarEmpresaScreen> createState() =>
      _CrearEditarEmpresaScreenState();
}

class _CrearEditarEmpresaScreenState extends State<CrearEditarEmpresaScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreEmpresaController;
  late final TextEditingController _nombreContactoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _correoController;
  late final TextEditingController _urlController;
  late final TextEditingController _montoController;
  late final TextEditingController _notasController;

  String _cicloPago = 'Mensual';
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  late bool _activa;
  bool _guardando = false;

  bool get _editando => widget.empresa != null;

  @override
  void initState() {
    super.initState();
    final empresa = widget.empresa;

    _nombreEmpresaController = TextEditingController(
      text: empresa?.nombreEmpresa ?? '',
    );
    _nombreContactoController = TextEditingController(
      text: empresa?.nombreContacto ?? '',
    );
    _telefonoController = TextEditingController(
      text: empresa?.telefonoContacto ?? '',
    );
    _correoController = TextEditingController(
      text: empresa?.correoContacto ?? '',
    );
    _urlController = TextEditingController(text: empresa?.urlInstalacion ?? '');
    _montoController = TextEditingController(
      text: empresa?.montoMembresia != null
          ? empresa!.montoMembresia!.toStringAsFixed(0)
          : '',
    );
    _notasController = TextEditingController(text: empresa?.notas ?? '');

    _cicloPago = empresa?.cicloPago ?? 'Mensual';
    final ahora = DateTime.now();
    _fechaInicio = empresa?.fechaInicioMembresia ?? ahora;
    _fechaFin =
        empresa?.fechaFinMembresia ?? ahora.add(const Duration(days: 30));
    _activa = empresa?.activa ?? true;
  }

  @override
  void dispose() {
    _nombreEmpresaController.dispose();
    _nombreContactoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _urlController.dispose();
    _montoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha.year}';
  }

  Future<void> _seleccionarFecha({required bool esInicio}) async {
    final actual = esInicio ? _fechaInicio : _fechaFin;
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (seleccionada == null) return;

    setState(() {
      if (esInicio) {
        _fechaInicio = seleccionada;
      } else {
        _fechaFin = seleccionada;
      }
    });
  }

  /// Atajo para extender la fecha de fin desde hoy (o desde el vencimiento
  /// actual si todavía no venció), el caso de uso más común: renovar.
  void _extenderMembresia(int meses) {
    final base = _fechaFin.isAfter(DateTime.now())
        ? _fechaFin
        : DateTime.now();
    setState(() {
      _fechaFin = DateTime(base.year, base.month + meses, base.day);
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaFin.isBefore(_fechaInicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha de fin no puede ser anterior a la de inicio',
          ),
          backgroundColor: LoginovaColors.error,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final monto = double.tryParse(_montoController.text.trim());
      final empresa = EmpresaCliente(
        id: widget.empresa?.id ?? 0,
        nombreEmpresa: _nombreEmpresaController.text.trim(),
        nombreContacto: _nombreContactoController.text.trim(),
        telefonoContacto: _telefonoController.text.trim(),
        correoContacto: _correoController.text.trim(),
        urlInstalacion: _urlController.text.trim(),
        fechaInicioMembresia: _fechaInicio,
        fechaFinMembresia: _fechaFin,
        montoMembresia: monto,
        cicloPago: _cicloPago,
        notas: _notasController.text.trim(),
        activa: _activa,
        fechaCreacion: widget.empresa?.fechaCreacion ?? DateTime.now(),
        estadoMembresia: widget.empresa?.estadoMembresia ?? 'Vigente',
        diasParaVencimiento: widget.empresa?.diasParaVencimiento ?? 0,
      );

      final provider = Provider.of<EmpresasClientesProvider>(
        context,
        listen: false,
      );

      if (_editando) {
        await provider.actualizarEmpresa(widget.empresa!.id, empresa);
      } else {
        await provider.agregarEmpresa(empresa);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editando ? 'Empresa actualizada' : 'Empresa registrada',
          ),
          backgroundColor: LoginovaColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: LoginovaColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar empresa' : 'Nueva empresa cliente'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Datos de la empresa'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombreEmpresaController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la empresa',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ingresa el nombre de la empresa'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL de su instalación',
                    hintText: 'https://empresa-api.onrender.com',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Contacto'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombreContactoController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del contacto',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (con código de país)',
                    hintText: 'Ej: 573001234567',
                    prefixIcon: Icon(Icons.phone),
                    helperText: 'Se usa para el recordatorio por WhatsApp',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Membresía'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectorFecha(
                        label: 'Inicio',
                        fecha: _fechaInicio,
                        onTap: () => _seleccionarFecha(esInicio: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSelectorFecha(
                        label: 'Vencimiento',
                        fecha: _fechaFin,
                        onTap: () => _seleccionarFecha(esInicio: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => _extenderMembresia(1),
                      child: const Text('+1 mes'),
                    ),
                    OutlinedButton(
                      onPressed: () => _extenderMembresia(12),
                      child: const Text('+1 año'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _cicloPago,
                  decoration: const InputDecoration(
                    labelText: 'Ciclo de pago',
                    prefixIcon: Icon(Icons.autorenew),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Mensual', child: Text('Mensual')),
                    DropdownMenuItem(value: 'Anual', child: Text('Anual')),
                    DropdownMenuItem(value: 'Único', child: Text('Pago único')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _cicloPago = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _montoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Monto (opcional)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Empresa activa'),
                  subtitle: const Text(
                    'Desactívala si dejó de ser cliente, sin borrar su historial',
                  ),
                  value: _activa,
                  onChanged: (value) => setState(() => _activa = value),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Notas de seguimiento'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notasController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Notas internas, no visibles para la empresa...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(_editando ? 'Guardar cambios' : 'Registrar empresa'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: LoginovaColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSelectorFecha({
    required String label,
    required DateTime fecha,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(_formatearFecha(fecha)),
      ),
    );
  }
}
