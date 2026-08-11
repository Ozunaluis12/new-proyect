import 'package:flutter/material.dart';

import '../constants/permission_constants.dart';
import '../models/cliente.dart';
import '../models/ingreso.dart';
import '../models/nota_soporte.dart';
import '../models/pago_membresia.dart';
import '../models/recogida.dart';
import '../models/resumen_soporte_empresa.dart';
import '../models/usuario.dart';
import '../services/empresa_service.dart';
import '../themes/app_theme.dart';
import '../widgets/responsive_center.dart';

/// Vista de soporte para una empresa específica: resumen de actividad,
/// usuarios con sus permisos (editables, con restablecer contraseña para
/// casos de bloqueo), auditoría y bitácora de notas de soporte. Exclusiva
/// del rol Soporte; reutiliza los mismos endpoints protegidos por
/// [Authorize(Roles = "Soporte")] que "impersonan" el tenant de la empresa
/// del lado del backend.
///
/// Recibe solo [empresaId] y [nombreEmpresa] (no el objeto [Empresa]
/// completo): es lo único que esta pantalla necesita, y así se puede abrir
/// también desde flujos que no cargaron la empresa completa (p. ej. el
/// buscador global por correo).
class SoporteEmpresaDetalleScreen extends StatefulWidget {
  final int empresaId;
  final String nombreEmpresa;

  const SoporteEmpresaDetalleScreen({
    super.key,
    required this.empresaId,
    required this.nombreEmpresa,
  });

  @override
  State<SoporteEmpresaDetalleScreen> createState() =>
      _SoporteEmpresaDetalleScreenState();
}

class _SoporteEmpresaDetalleScreenState
    extends State<SoporteEmpresaDetalleScreen>
    with SingleTickerProviderStateMixin {
  final _service = EmpresaService();
  late final TabController _tabController;
  final _notaController = TextEditingController();

  bool _cargando = true;
  String? _error;
  List<Usuario> _usuarios = [];
  ResumenSoporteEmpresa? _resumen;
  List<Map<String, dynamic>> _auditoria = [];
  List<NotaSoporte> _notas = [];
  List<Cliente> _clientes = [];
  List<Recogida> _recogidas = [];
  List<Ingreso> _ingresos = [];
  List<PagoMembresia> _pagos = [];
  bool _guardandoNota = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultados = await Future.wait([
        _service.obtenerUsuariosDeEmpresa(widget.empresaId),
        _service.obtenerResumenEmpresa(widget.empresaId),
        _service.obtenerAuditoriaEmpresa(widget.empresaId),
        _service.obtenerNotasSoporte(widget.empresaId),
        _service.obtenerClientesDeEmpresa(widget.empresaId),
        _service.obtenerRecogidasDeEmpresa(widget.empresaId),
        _service.obtenerIngresosDeEmpresa(widget.empresaId),
        _service.obtenerPagosMembresia(widget.empresaId),
      ]);
      if (!mounted) return;
      setState(() {
        _usuarios = resultados[0] as List<Usuario>;
        _resumen = resultados[1] as ResumenSoporteEmpresa;
        _auditoria = resultados[2] as List<Map<String, dynamic>>;
        _notas = resultados[3] as List<NotaSoporte>;
        _clientes = resultados[4] as List<Cliente>;
        _recogidas = resultados[5] as List<Recogida>;
        _ingresos = resultados[6] as List<Ingreso>;
        _pagos = resultados[7] as List<PagoMembresia>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _editarPermisos(Usuario usuario) async {
    final seleccionados = {...usuario.permisos};

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permisos de ${usuario.nombre}',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      usuario.correo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LoginovaColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: PermissionConstants.all.map((permiso) {
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: seleccionados.contains(permiso),
                              title: Text(
                                PermissionConstants.labels[permiso] ??
                                    permiso,
                              ),
                              onChanged: (checked) {
                                setSheetState(() {
                                  if (checked == true) {
                                    seleccionados.add(permiso);
                                  } else {
                                    seleccionados.remove(permiso);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: const Text('Guardar permisos'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (guardar != true || !mounted) return;

    try {
      await _service.actualizarPermisosUsuario(
        empresaId: widget.empresaId,
        usuarioId: usuario.id,
        permisos: seleccionados.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permisos actualizados'),
          backgroundColor: LoginovaColors.success,
        ),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: LoginovaColors.error,
        ),
      );
    }
  }

  Future<void> _restablecerPassword(Usuario usuario) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: Text(
          '¿Generar una contraseña temporal nueva para ${usuario.nombre}? '
          'La contraseña actual deja de funcionar de inmediato.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: LoginovaColors.warning),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    try {
      final passwordTemporal = await _service.restablecerPassword(
        empresaId: widget.empresaId,
        usuarioId: usuario.id,
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Contraseña temporal generada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comunícasela a ${usuario.nombre} y pídele que la cambie '
                'de inmediato. No se volverá a mostrar.',
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LoginovaColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LoginovaColors.divider),
                ),
                child: SelectableText(
                  passwordTemporal,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: LoginovaColors.error,
        ),
      );
    }
  }

  Future<void> _cambiarEstadoUsuario(Usuario usuario, bool activar) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(activar ? 'Activar acceso' : 'Desactivar acceso'),
        content: Text(
          activar
              ? '¿Reactivar el acceso de ${usuario.nombre}? Podrá volver a iniciar sesión de inmediato.'
              : '¿Desactivar el acceso de ${usuario.nombre}? Pierde acceso de inmediato '
                    '(aunque tenga una sesión abierta), sin afectar al resto de usuarios de la empresa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: activar ? LoginovaColors.success : LoginovaColors.error,
            ),
            child: Text(activar ? 'Activar' : 'Desactivar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    try {
      await _service.cambiarEstadoUsuario(
        empresaId: widget.empresaId,
        usuarioId: usuario.id,
        activo: activar,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(activar ? 'Acceso reactivado' : 'Acceso desactivado'),
          backgroundColor: LoginovaColors.success,
        ),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: LoginovaColors.error,
        ),
      );
    }
  }

  Future<void> _registrarPago() async {
    final montoController = TextEditingController();
    final notasController = TextEditingController();
    String cicloPago = 'Mensual';
    final formKey = GlobalKey<FormState>();

    final registrar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Registrar pago de membresía'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: montoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto'),
                  validator: (value) {
                    final monto = double.tryParse(value ?? '');
                    return (monto == null || monto <= 0) ? 'Ingresa un monto válido' : null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: cicloPago,
                  decoration: const InputDecoration(labelText: 'Ciclo'),
                  items: const [
                    DropdownMenuItem(value: 'Mensual', child: Text('Mensual')),
                    DropdownMenuItem(value: 'Anual', child: Text('Anual')),
                    DropdownMenuItem(value: 'Único', child: Text('Pago único')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => cicloPago = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notasController,
                  decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );

    if (registrar != true || !mounted) return;

    try {
      await _service.crearPagoMembresia(
        empresaId: widget.empresaId,
        monto: double.parse(montoController.text),
        cicloPago: cicloPago,
        notas: notasController.text.trim().isEmpty ? null : notasController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago registrado'),
          backgroundColor: LoginovaColors.success,
        ),
      );
      final pagos = await _service.obtenerPagosMembresia(widget.empresaId);
      if (!mounted) return;
      setState(() => _pagos = pagos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: LoginovaColors.error),
      );
    }
  }

  Future<void> _agregarNota() async {
    final contenido = _notaController.text.trim();
    if (contenido.isEmpty) return;

    setState(() => _guardandoNota = true);
    try {
      await _service.crearNotaSoporte(
        empresaId: widget.empresaId,
        contenido: contenido,
      );
      _notaController.clear();
      final notas = await _service.obtenerNotasSoporte(widget.empresaId);
      if (!mounted) return;
      setState(() => _notas = notas);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: LoginovaColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardandoNota = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreEmpresa),
        elevation: 0,
        bottom: _cargando || _error != null
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Resumen', icon: Icon(Icons.dashboard_outlined)),
                  Tab(text: 'Usuarios', icon: Icon(Icons.people_outline)),
                  Tab(text: 'Clientes', icon: Icon(Icons.business_outlined)),
                  Tab(text: 'Recogidas', icon: Icon(Icons.local_shipping_outlined)),
                  Tab(text: 'Ingresos', icon: Icon(Icons.payments_outlined)),
                  Tab(text: 'Pagos', icon: Icon(Icons.receipt_long_outlined)),
                  Tab(text: 'Auditoría', icon: Icon(Icons.fact_check_outlined)),
                  Tab(text: 'Notas', icon: Icon(Icons.sticky_note_2_outlined)),
                ],
              ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _cargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildResumenTab(),
                _buildUsuariosTab(),
                _buildClientesTab(),
                _buildRecogidasTab(),
                _buildIngresosTab(),
                _buildPagosTab(),
                _buildAuditoriaTab(),
                _buildNotasTab(),
              ],
            ),
    );
  }

  Widget _buildResumenTab() {
    if (_resumen == null) return const SizedBox.shrink();
    return RefreshIndicator(
      onRefresh: _cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: ResponsiveCenter(maxWidth: 800, child: _buildResumen(_resumen!)),
      ),
    );
  }

  Widget _buildResumen(ResumenSoporteEmpresa resumen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 700
            ? 3
            : constraints.maxWidth >= 450
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: [
            _buildResumenCard(
              'Usuarios',
              resumen.totalUsuarios.toString(),
              Icons.people,
              LoginovaColors.primary,
            ),
            _buildResumenCard(
              'Clientes',
              resumen.totalClientes.toString(),
              Icons.business,
              LoginovaColors.info,
            ),
            _buildResumenCard(
              'Recogidas totales',
              resumen.totalRecogidas.toString(),
              Icons.local_shipping,
              LoginovaColors.secondary,
            ),
            _buildResumenCard(
              'Pendientes',
              resumen.recogidasPendientes.toString(),
              Icons.hourglass_empty,
              LoginovaColors.warning,
            ),
            _buildResumenCard(
              'Ingresos registrados',
              '${resumen.totalIngresos} (\$${resumen.montoTotalIngresos.toStringAsFixed(2)})',
              Icons.payments,
              LoginovaColors.success,
            ),
            _buildResumenCard(
              'Última recogida',
              resumen.ultimaRecogida == null
                  ? 'Sin actividad'
                  : _formatearFecha(resumen.ultimaRecogida!),
              Icons.event,
              LoginovaColors.textSecondary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildResumenCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsuariosTab() {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ResponsiveCenter(
        maxWidth: 800,
        child: _usuarios.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('Esta empresa todavía no tiene usuarios.')),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _usuarios.length,
                itemBuilder: (context, index) => _buildUsuarioTile(_usuarios[index]),
              ),
      ),
    );
  }

  Widget _buildUsuarioTile(Usuario usuario) {
    final activo = usuario.activo;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(usuario.nombre),
        subtitle: Text('${usuario.correo} · ${usuario.rol}'),
        leading: activo
            ? null
            : const Tooltip(
                message: 'Acceso desactivado',
                child: Icon(Icons.block, color: LoginovaColors.error),
              ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (accion) {
            if (accion == 'permisos') {
              _editarPermisos(usuario);
            } else if (accion == 'password') {
              _restablecerPassword(usuario);
            } else if (accion == 'estado') {
              _cambiarEstadoUsuario(usuario, !activo);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'permisos',
              child: ListTile(
                leading: Icon(Icons.security),
                title: Text('Editar permisos'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'password',
              child: ListTile(
                leading: Icon(Icons.lock_reset),
                title: Text('Restablecer contraseña'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'estado',
              child: ListTile(
                leading: Icon(activo ? Icons.block : Icons.check_circle_outline),
                title: Text(activo ? 'Desactivar acceso' : 'Activar acceso'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientesTab() {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ResponsiveCenter(
        maxWidth: 800,
        child: _clientes.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('Esta empresa todavía no tiene clientes.')),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _clientes.length,
                itemBuilder: (context, index) {
                  final cliente = _clientes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.business),
                      title: Text(cliente.nombre),
                      subtitle: Text(
                        [
                          cliente.telefono,
                          cliente.direccion,
                          cliente.ciudad,
                        ].where((v) => v.isNotEmpty).join(' · '),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildRecogidasTab() {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ResponsiveCenter(
        maxWidth: 800,
        child: _recogidas.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('Esta empresa todavía no tiene recogidas.')),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _recogidas.length,
                itemBuilder: (context, index) {
                  final recogida = _recogidas[index];
                  final color = switch (recogida.estado.toLowerCase()) {
                    'recogida' => LoginovaColors.success,
                    'cancelada' => LoginovaColors.error,
                    _ => LoginovaColors.warning,
                  };
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(Icons.local_shipping, color: color),
                      ),
                      title: Text('#${recogida.id} · ${recogida.clienteNombre ?? 'Cliente #${recogida.clienteId}'}'),
                      subtitle: Text(
                        '${recogida.estado} · ${recogida.cantidadPaquetes} paquete(s)'
                        '${recogida.usuarioNombre != null ? ' · ${recogida.usuarioNombre}' : ''}'
                        '${recogida.fechaCreacion != null ? ' · ${_formatearFecha(recogida.fechaCreacion!)}' : ''}',
                      ),
                      trailing: recogida.dineroRecibido && recogida.montoCobrado != null
                          ? Text(
                              '\$${recogida.montoCobrado!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: LoginovaColors.success,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildIngresosTab() {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ResponsiveCenter(
        maxWidth: 800,
        child: _ingresos.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('Esta empresa todavía no tiene ingresos registrados.')),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _ingresos.length,
                itemBuilder: (context, index) {
                  final ingreso = _ingresos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.payments, color: LoginovaColors.success),
                      title: Text(ingreso.clienteNombre),
                      subtitle: Text(
                        '${ingreso.responsableNombre} · ${ingreso.formaPago} · '
                        '${_formatearFecha(ingreso.fechaIngreso)}',
                      ),
                      trailing: Text(
                        '\$${ingreso.monto.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: LoginovaColors.success,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildPagosTab() {
    return ResponsiveCenter(
      maxWidth: 800,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Historial de pagos de membresía',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _registrarPago,
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar pago'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _cargar,
                child: _pagos.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 60),
                          Center(child: Text('Sin pagos registrados todavía.')),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _pagos.length,
                        itemBuilder: (context, index) {
                          final pago = _pagos[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.receipt_long, color: LoginovaColors.primary),
                              title: Text(
                                '\$${pago.monto.toStringAsFixed(2)}'
                                '${pago.cicloPago != null ? ' · ${pago.cicloPago}' : ''}',
                              ),
                              subtitle: Text(
                                '${_formatearFecha(pago.fechaPago)} · ${pago.registradoPorNombre}'
                                '${(pago.notas ?? '').isNotEmpty ? '\n${pago.notas}' : ''}',
                              ),
                              isThreeLine: (pago.notas ?? '').isNotEmpty,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditoriaTab() {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ResponsiveCenter(
        maxWidth: 800,
        child: _auditoria.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('Sin registros de auditoría todavía.')),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _auditoria.length,
                itemBuilder: (context, index) => _buildAuditoriaTile(_auditoria[index]),
              ),
      ),
    );
  }

  Widget _buildAuditoriaTile(Map<String, dynamic> log) {
    final accion = (log['accion'] ?? 'N/A').toString();
    final color = switch (accion.toUpperCase()) {
      'CREATE' => LoginovaColors.success,
      'UPDATE' => LoginovaColors.info,
      'DELETE' => LoginovaColors.error,
      _ => LoginovaColors.textSecondary,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.fact_check, color: color),
        ),
        title: Text(
          '${(log['entidadTipo'] ?? 'Entidad').toString()} #${(log['entidadId'] ?? '-').toString()}',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text((log['descripcion'] ?? 'Sin descripción').toString()),
            const SizedBox(height: 4),
            Text(
              _formatearFechaHora(log['fechaCambio']),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
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
  }

  Widget _buildNotasTab() {
    return ResponsiveCenter(
      maxWidth: 800,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bitácora de soporte',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Deja un registro de cada interacción, para llevar memoria si '
              'más de una persona atiende a esta empresa.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _notaController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Cliente llamó preguntando por...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _guardandoNota ? null : _agregarNota,
                  icon: _guardandoNota
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _cargar,
                child: _notas.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 60),
                          Center(child: Text('Sin notas todavía.')),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _notas.length,
                        itemBuilder: (context, index) => _buildNotaTile(_notas[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotaTile(NotaSoporte nota) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nota.contenido),
            const SizedBox(height: 6),
            Text(
              '${nota.creadoPorNombre} · ${_formatearFechaHora(nota.fechaCreacion.toIso8601String())}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: LoginovaColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha.year}';
  }

  String _formatearFechaHora(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'Sin fecha';
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
