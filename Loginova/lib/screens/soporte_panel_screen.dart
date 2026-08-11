import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/dashboard_soporte.dart';
import '../models/empresa.dart';
import '../providers/auth_provider.dart';
import '../providers/empresas_provider.dart';
import '../services/configuracion_soporte_service.dart';
import '../services/empresa_service.dart';
import '../themes/app_theme.dart';
import 'crear_editar_empresa_screen.dart';
import 'soporte_buscador_screen.dart';
import 'soporte_empresa_detalle_screen.dart';
import 'soporte_equipo_screen.dart';

/// Panel de Soporte: administra las empresas (tenants) que compraron
/// Loginova en este mismo backend compartido — altas (junto con su primer
/// Administrador), fechas de membresía, recordatorios y
/// activación/suspensión. Exclusivo del rol Soporte, que no pertenece a
/// ninguna empresa; por eso esta pantalla no usa el MenuDrawer normal (ese
/// menú es para usuarios dentro de una empresa) y solo ofrece cerrar sesión.
class SoportePanelScreen extends StatefulWidget {
  const SoportePanelScreen({super.key});

  @override
  State<SoportePanelScreen> createState() => _SoportePanelScreenState();
}

class _SoportePanelScreenState extends State<SoportePanelScreen> {
  final _empresaService = EmpresaService();
  final _configuracionService = ConfiguracionSoporteService();
  final _busquedaController = TextEditingController();
  String _busqueda = '';
  String _filtroEstado = 'TODAS';
  DashboardSoporte? _dashboard;
  bool _exportando = false;

  // Plantillas de recordatorio: se cargan del backend (editables desde el
  // ícono de ajustes); estos valores solo se usan como respaldo si todavía
  // no terminó de cargar o si la carga falla.
  String _plantillaVigente =
      'Hola {contacto}, te escribimos de Loginova: la membresía de {empresa} '
      'vence el {fecha}. ¿Deseas que gestionemos la renovación?';
  String _plantillaVencida =
      'Hola {contacto}, te escribimos de Loginova: la membresía de {empresa} '
      'venció el {fecha}. ¿Deseas renovarla para seguir usando el sistema '
      'sin interrupciones?';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmpresasProvider>(context, listen: false).cargarEmpresas();
      _cargarDashboard();
      _cargarPlantillas();
    });
  }

  Future<void> _cargarPlantillas() async {
    try {
      final config = await _configuracionService.obtener();
      if (!mounted) return;
      setState(() {
        _plantillaVigente = config['plantillaRecordatorioVigente']!;
        _plantillaVencida = config['plantillaRecordatorioVencida']!;
      });
    } catch (_) {
      // Si falla, se siguen usando las plantillas por defecto de arriba.
    }
  }

  Future<void> _editarPlantillas() async {
    final vigenteController = TextEditingController(text: _plantillaVigente);
    final vencidaController = TextEditingController(text: _plantillaVencida);

    final guardar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Plantillas de WhatsApp'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Placeholders disponibles: {contacto}, {empresa}, {fecha}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              const Text('Membresía vigente (recordatorio anticipado)'),
              const SizedBox(height: 4),
              TextField(
                controller: vigenteController,
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              const Text('Membresía vencida'),
              const SizedBox(height: 4),
              TextField(
                controller: vencidaController,
                minLines: 2,
                maxLines: 4,
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
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardar != true || !mounted) return;

    try {
      await _configuracionService.actualizar(
        plantillaVigente: vigenteController.text,
        plantillaVencida: vencidaController.text,
      );
      if (!mounted) return;
      setState(() {
        _plantillaVigente = vigenteController.text;
        _plantillaVencida = vencidaController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plantillas actualizadas'),
          backgroundColor: LoginovaColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: LoginovaColors.error),
      );
    }
  }

  void _abrirBuscador() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SoporteBuscadorScreen()),
    );
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDashboard() async {
    try {
      final dashboard = await _empresaService.obtenerDashboard();
      if (!mounted) return;
      setState(() => _dashboard = dashboard);
    } catch (_) {
      // El resumen agregado es informativo, no bloqueante: si falla, el
      // panel sigue funcionando normal sin él.
    }
  }

  // XFile.fromData (bytes en memoria) en vez de escribir a un archivo
  // temporal con path_provider: path_provider no tiene implementación para
  // Flutter Web, así que escribir a disco fallaría ahí; XFile.fromData
  // funciona igual en todas las plataformas (en web dispara la descarga
  // del navegador).
  Future<void> _exportarCsv() async {
    setState(() => _exportando = true);
    try {
      final bytes = await _empresaService.exportarEmpresasCsv();

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: 'empresas_${DateTime.now().millisecondsSinceEpoch}.csv',
              mimeType: 'text/csv',
            ),
          ],
          text: 'Listado de empresas',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exportando CSV: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Suspendida':
        return LoginovaColors.textSecondary;
      case 'Vencida':
        return LoginovaColors.error;
      case 'PorVencer':
        return LoginovaColors.warning;
      default:
        return LoginovaColors.success;
    }
  }

  String _etiquetaEstado(String estado) {
    switch (estado) {
      case 'Suspendida':
        return 'Suspendida';
      case 'Vencida':
        return 'Vencida';
      case 'PorVencer':
        return 'Por vencer';
      default:
        return 'Vigente';
    }
  }

  String _formatearFecha(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha.year}';
  }

  /// Aplica la búsqueda por nombre/contacto y el filtro de estado sobre la
  /// lista ya cargada, sin volver a pedirla al backend.
  List<Empresa> _empresasFiltradas(List<Empresa> empresas) {
    var resultado = _filtroEstado == 'TODAS'
        ? empresas
        : empresas.where((e) => e.estadoMembresia == _filtroEstado).toList();

    final query = _busqueda.trim().toLowerCase();
    if (query.isEmpty) return resultado;

    return resultado.where((e) {
      final nombre = e.nombreEmpresa.toLowerCase();
      final contacto = (e.nombreContacto ?? '').toLowerCase();
      final telefono = (e.telefonoContacto ?? '').toLowerCase();
      return nombre.contains(query) ||
          contacto.contains(query) ||
          telefono.contains(query);
    }).toList();
  }

  /// Abre WhatsApp con un mensaje de recordatorio ya redactado para el
  /// contacto de la empresa. No usa ninguna API de WhatsApp (esto sería
  /// costoso/complejo de mantener): es el link estándar de "click to chat",
  /// gratis, que abre WhatsApp con el texto precargado para que Soporte lo
  /// revise y lo envíe manualmente.
  Future<void> _recordarPorWhatsapp(Empresa empresa) async {
    final telefono = (empresa.telefonoContacto ?? '').replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    if (telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta empresa no tiene teléfono de contacto'),
          backgroundColor: LoginovaColors.error,
        ),
      );
      return;
    }

    final contacto = (empresa.nombreContacto ?? '').isNotEmpty
        ? empresa.nombreContacto!
        : empresa.nombreEmpresa;

    final plantilla = empresa.diasParaVencimiento < 0
        ? _plantillaVencida
        : _plantillaVigente;

    final mensaje = plantilla
        .replaceAll('{contacto}', contacto)
        .replaceAll('{empresa}', empresa.nombreEmpresa)
        .replaceAll('{fecha}', _formatearFecha(empresa.fechaFinMembresia));

    final uri = Uri.parse(
      'https://wa.me/$telefono?text=${Uri.encodeComponent(mensaje)}',
    );

    final abierto = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!abierto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
      return;
    }

    if (!mounted) return;
    // Se ofrece marcar el recordatorio como enviado después de volver de
    // WhatsApp; no se marca automático porque abrir el chat no confirma
    // que el mensaje realmente se envió.
    final marcar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Enviaste el recordatorio?'),
        content: const Text(
          'Si confirmaste el envío en WhatsApp, marca la fecha de hoy '
          'como último recordatorio para llevar el seguimiento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No, todavía no'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, marcar como enviado'),
          ),
        ],
      ),
    );

    if (marcar == true && mounted) {
      await Provider.of<EmpresasProvider>(
        context,
        listen: false,
      ).marcarRecordatorioEnviado(empresa.id);
    }
  }

  void _abrirFormulario({Empresa? empresa}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearEditarEmpresaScreen(empresa: empresa),
      ),
    );
  }

  void _abrirDetalle(Empresa empresa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SoporteEmpresaDetalleScreen(
          empresaId: empresa.id,
          nombreEmpresa: empresa.nombreEmpresa,
        ),
      ),
    );
  }

  void _abrirEquipo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SoporteEquipoScreen()),
    );
  }

  Future<void> _confirmarCambiarActiva(Empresa empresa) async {
    final activar = !empresa.activa;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(activar ? 'Activar empresa' : 'Suspender empresa'),
        content: Text(
          activar
              ? '¿Reactivar "${empresa.nombreEmpresa}"? Todos sus usuarios '
                    'recuperan acceso de inmediato.'
              : '¿Suspender "${empresa.nombreEmpresa}"? TODOS sus usuarios '
                    '(administrador, operadores, etc.) pierden acceso de '
                    'inmediato, sin importar la fecha de vencimiento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: activar
                  ? LoginovaColors.success
                  : LoginovaColors.error,
            ),
            child: Text(activar ? 'Activar' : 'Suspender'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    final provider = Provider.of<EmpresasProvider>(context, listen: false);
    if (activar) {
      await provider.activarEmpresa(empresa.id);
    } else {
      await provider.suspenderEmpresa(empresa.id);
    }
    await _cargarDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Soporte'),
        elevation: 0,
        // Menú de opciones en vez de varios IconButton sueltos: con 5
        // acciones posibles, ponerlas todas como íconos directos se
        // desborda en un celular angosto (el mismo problema que ya
        // corregimos en la tarjeta de empresa). Solo "Cerrar sesión" queda
        // como ícono directo, por ser la acción más usada.
        actions: [
          if (_exportando)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (accion) {
              switch (accion) {
                case 'buscar':
                  _abrirBuscador();
                case 'exportar':
                  _exportarCsv();
                case 'equipo':
                  _abrirEquipo();
                case 'plantillas':
                  _editarPlantillas();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'buscar',
                child: ListTile(
                  leading: Icon(Icons.person_search),
                  title: Text('Buscar por correo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'exportar',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Exportar CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'equipo',
                child: ListTile(
                  leading: Icon(Icons.groups),
                  title: Text('Equipo de Soporte'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'plantillas',
                child: ListTile(
                  leading: Icon(Icons.chat_outlined),
                  title: Text('Plantillas de WhatsApp'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await Provider.of<AuthProvider>(
                context,
                listen: false,
              ).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add_business),
        label: const Text('Nueva empresa'),
      ),
      body: Consumer<EmpresasProvider>(
        builder: (context, provider, _) {
          if (provider.cargando) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.empresas.isEmpty) {
            return _buildEmptyState();
          }

          final empresasFiltradas = _empresasFiltradas(provider.empresas);

          return RefreshIndicator(
            onRefresh: () async {
              await provider.cargarEmpresas();
              await _cargarDashboard();
            },
            child: Column(
              children: [
                if (_dashboard != null) _buildDashboard(_dashboard!),
                _buildBusquedaYFiltros(),
                Expanded(
                  child: empresasFiltradas.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(
                              child: Text('Ninguna empresa coincide con la búsqueda.'),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: empresasFiltradas.length,
                          itemBuilder: (context, index) =>
                              _buildEmpresaCard(empresasFiltradas[index]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(DashboardSoporte dashboard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildDashboardCard(
              'Empresas activas',
              '${dashboard.empresasActivas}/${dashboard.totalEmpresas}',
              Icons.business,
              LoginovaColors.primary,
            ),
            const SizedBox(width: 8),
            _buildDashboardCard(
              'Ingreso mensual est.',
              '\$${dashboard.ingresoMensualEstimado.toStringAsFixed(0)}',
              Icons.payments,
              LoginovaColors.success,
            ),
            const SizedBox(width: 8),
            _buildDashboardCard(
              'Por vencer (7 días)',
              dashboard.empresasPorVencer.toString(),
              Icons.warning_amber,
              LoginovaColors.warning,
            ),
            const SizedBox(width: 8),
            _buildDashboardCard(
              'Vencidas',
              dashboard.empresasVencidas.toString(),
              Icons.error_outline,
              LoginovaColors.error,
            ),
            const SizedBox(width: 8),
            _buildDashboardCard(
              'Sin actividad (30d)',
              dashboard.empresasSinActividadReciente.toString(),
              Icons.bedtime,
              LoginovaColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildBusquedaYFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: _busquedaController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o contacto',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busqueda.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _busquedaController.clear();
                        setState(() => _busqueda = '');
                      },
                    ),
            ),
            onChanged: (value) => setState(() => _busqueda = value),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              children: ['TODAS', 'Vigente', 'PorVencer', 'Vencida', 'Suspendida']
                  .map(
                    (estado) => ChoiceChip(
                      label: Text(estado == 'PorVencer' ? 'Por vencer' : estado),
                      selected: _filtroEstado == estado,
                      onSelected: (_) => setState(() => _filtroEstado = estado),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpresaCard(Empresa empresa) {
    final color = _colorEstado(empresa.estadoMembresia);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: empresa.estadoMembresia == 'Suspendida'
          ? LoginovaColors.textSecondary.withValues(alpha: 0.08)
          : empresa.estadoMembresia == 'Vencida'
          ? LoginovaColors.error.withValues(alpha: 0.08)
          : empresa.estadoMembresia == 'PorVencer'
          ? LoginovaColors.warning.withValues(alpha: 0.08)
          : null,
      child: InkWell(
        onTap: () => _abrirFormulario(empresa: empresa),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      empresa.nombreEmpresa,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      border: Border.all(color: color),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _etiquetaEstado(empresa.estadoMembresia),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Vence: ${_formatearFecha(empresa.fechaFinMembresia)}'
                '${empresa.diasParaVencimiento >= 0 ? ' (${empresa.diasParaVencimiento} días)' : ' (vencida hace ${-empresa.diasParaVencimiento} días)'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: color),
              ),
              if ((empresa.nombreContacto ?? '').isNotEmpty ||
                  (empresa.telefonoContacto ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    empresa.nombreContacto,
                    empresa.telefonoContacto,
                  ].where((v) => (v ?? '').isNotEmpty).join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LoginovaColors.textSecondary,
                  ),
                ),
              ],
              if (empresa.ultimoRecordatorioEnviado != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Último recordatorio: ${_formatearFecha(empresa.ultimoRecordatorioEnviado!)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: LoginovaColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // Wrap en vez de Row: con 4 acciones posibles, un celular
              // angosto no alcanza a mostrarlas todas en una sola línea.
              // Wrap las pasa a una segunda línea en vez de desbordar la
              // tarjeta (que es justo lo que pasaba con Row).
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  if ((empresa.telefonoContacto ?? '').isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _recordarPorWhatsapp(empresa),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('WhatsApp'),
                    ),
                  TextButton.icon(
                    onPressed: () => _abrirDetalle(empresa),
                    icon: const Icon(Icons.support_agent, size: 18),
                    label: const Text('Detalle'),
                  ),
                  TextButton.icon(
                    onPressed: () => _abrirFormulario(empresa: empresa),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmarCambiarActiva(empresa),
                    icon: Icon(
                      empresa.activa
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 18,
                    ),
                    label: Text(empresa.activa ? 'Suspender' : 'Activar'),
                    style: TextButton.styleFrom(
                      foregroundColor: empresa.activa
                          ? LoginovaColors.error
                          : LoginovaColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: LoginovaColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Todavía no registraste ninguna empresa',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: LoginovaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add_business),
              label: const Text('Registrar empresa'),
            ),
          ],
        ),
      ),
    );
  }
}
