import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/empresa.dart';
import '../providers/auth_provider.dart';
import '../providers/empresas_provider.dart';
import '../themes/app_theme.dart';
import 'crear_editar_empresa_screen.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmpresasProvider>(context, listen: false).cargarEmpresas();
    });
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

    final mensaje = empresa.diasParaVencimiento < 0
        ? 'Hola $contacto, te escribimos de Loginova: la membresía de '
              '${empresa.nombreEmpresa} venció el '
              '${_formatearFecha(empresa.fechaFinMembresia)}. '
              '¿Deseas renovarla para seguir usando el sistema sin '
              'interrupciones?'
        : 'Hola $contacto, te escribimos de Loginova: la membresía de '
              '${empresa.nombreEmpresa} vence el '
              '${_formatearFecha(empresa.fechaFinMembresia)}. '
              '¿Deseas que gestionemos la renovación?';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Soporte'),
        elevation: 0,
        actions: [
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

          final vencidas = provider.empresas
              .where((e) => e.estadoMembresia == 'Vencida')
              .length;
          final porVencer = provider.empresas
              .where((e) => e.estadoMembresia == 'PorVencer')
              .length;
          final suspendidas = provider.empresas
              .where((e) => e.estadoMembresia == 'Suspendida')
              .length;

          return RefreshIndicator(
            onRefresh: provider.cargarEmpresas,
            child: Column(
              children: [
                if (vencidas > 0 || porVencer > 0 || suspendidas > 0)
                  _buildResumen(vencidas, porVencer, suspendidas),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.empresas.length,
                    itemBuilder: (context, index) =>
                        _buildEmpresaCard(provider.empresas[index]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumen(int vencidas, int porVencer, int suspendidas) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: LoginovaColors.background,
      child: Wrap(
        spacing: 8,
        children: [
          if (vencidas > 0)
            Chip(
              avatar: const Icon(Icons.error, color: Colors.white, size: 18),
              label: Text('$vencidas vencida${vencidas == 1 ? '' : 's'}'),
              backgroundColor: LoginovaColors.error,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          if (porVencer > 0)
            Chip(
              avatar: const Icon(
                Icons.warning,
                color: Colors.white,
                size: 18,
              ),
              label: Text('$porVencer por vencer (7 días)'),
              backgroundColor: LoginovaColors.warning,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          if (suspendidas > 0)
            Chip(
              avatar: const Icon(
                Icons.pause_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                '$suspendidas suspendida${suspendidas == 1 ? '' : 's'}',
              ),
              backgroundColor: LoginovaColors.textSecondary,
              labelStyle: const TextStyle(color: Colors.white),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if ((empresa.telefonoContacto ?? '').isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _recordarPorWhatsapp(empresa),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('WhatsApp'),
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
