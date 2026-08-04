import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/empresa.dart';
import '../providers/empresas_provider.dart';
import '../themes/app_theme.dart';

/// Formulario del Panel de Soporte para registrar o editar una empresa
/// (tenant). Al crear, pide además los datos de su primer Administrador
/// (quien "compra" el servicio y luego crea sus propios operadores); al
/// editar, solo se tocan los datos de la empresa y su membresía.
class CrearEditarEmpresaScreen extends StatefulWidget {
  /// Si viene null, es creación; si trae una empresa, es edición.
  final Empresa? empresa;

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
  late final TextEditingController _montoController;
  late final TextEditingController _notasController;

  late final TextEditingController _adminNombreController;
  late final TextEditingController _adminCorreoController;
  late final TextEditingController _adminPasswordController;
  bool _mostrarAdminPassword = false;

  String _cicloPago = 'Mensual';
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
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
    _montoController = TextEditingController(
      text: empresa?.montoMembresia != null
          ? empresa!.montoMembresia!.toStringAsFixed(0)
          : '',
    );
    _notasController = TextEditingController(text: empresa?.notas ?? '');

    _adminNombreController = TextEditingController();
    _adminCorreoController = TextEditingController();
    _adminPasswordController = TextEditingController();

    _cicloPago = empresa?.cicloPago ?? 'Mensual';
    final ahora = DateTime.now();
    _fechaInicio = empresa?.fechaInicioMembresia ?? ahora;
    _fechaFin =
        empresa?.fechaFinMembresia ?? ahora.add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _nombreEmpresaController.dispose();
    _nombreContactoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _montoController.dispose();
    _notasController.dispose();
    _adminNombreController.dispose();
    _adminCorreoController.dispose();
    _adminPasswordController.dispose();
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
      final empresa = Empresa(
        id: widget.empresa?.id ?? 0,
        nombreEmpresa: _nombreEmpresaController.text.trim(),
        nombreContacto: _nombreContactoController.text.trim(),
        telefonoContacto: _telefonoController.text.trim(),
        correoContacto: _correoController.text.trim(),
        fechaInicioMembresia: _fechaInicio,
        fechaFinMembresia: _fechaFin,
        montoMembresia: monto,
        cicloPago: _cicloPago,
        notas: _notasController.text.trim(),
        activa: widget.empresa?.activa ?? true,
        fechaCreacion: widget.empresa?.fechaCreacion ?? DateTime.now(),
        estadoMembresia: widget.empresa?.estadoMembresia ?? 'Vigente',
        diasParaVencimiento: widget.empresa?.diasParaVencimiento ?? 0,
      );

      final provider = Provider.of<EmpresasProvider>(context, listen: false);

      if (_editando) {
        await provider.actualizarEmpresa(widget.empresa!.id, empresa);
      } else {
        await provider.crearEmpresa(
          empresa: empresa,
          adminNombre: _adminNombreController.text.trim(),
          adminCorreo: _adminCorreoController.text.trim(),
          adminPassword: _adminPasswordController.text,
        );
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
        title: Text(_editando ? 'Editar empresa' : 'Nueva empresa'),
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

                // Los datos del primer Administrador solo se piden al crear:
                // el backend crea la empresa y su admin en un solo paso, y
                // editar una empresa nunca toca a su administrador.
                if (!_editando) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle('Primer administrador'),
                  const SizedBox(height: 4),
                  Text(
                    'Esta cuenta podrá iniciar sesión de inmediato y crear '
                    'sus propios operadores.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LoginovaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _adminNombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del administrador',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Ingresa el nombre del administrador'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminCorreoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo del administrador',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa el correo del administrador';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminPasswordController,
                    obscureText: !_mostrarAdminPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña inicial',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarAdminPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _mostrarAdminPassword = !_mostrarAdminPassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Mínimo 8 caracteres';
                      }
                      return null;
                    },
                  ),
                ],
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
