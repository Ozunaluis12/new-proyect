import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/permission_constants.dart';
import '../providers/auth_provider.dart';
import '../services/mi_empresa_service.dart';
import '../themes/app_theme.dart';

/// Drawer de navegación principal de la app: muestra opciones distintas
/// según el rol y los permisos del usuario logueado (por ejemplo, "Panel
/// Admin" y "Auditoría" solo aparecen para Administrador).
class MenuDrawer extends StatelessWidget {
  /// Ruta actual, usada para resaltar el ítem seleccionado en el menú.
  final String currentRoute;

  const MenuDrawer({super.key, required this.currentRoute});

  // Número de WhatsApp de Soporte (con código de país de Colombia, 57), al
  // que se dirige el botón "Contactar Soporte", visible para cualquier
  // usuario autenticado de una empresa (no solo el Administrador).
  static const String _telefonoSoporte = '573004177979';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final usuario = auth.usuario;
    final isAdmin = usuario?.rol.toLowerCase() == 'administrador';
    // El Administrador siempre puede ver cierres; los demás roles
    // necesitan el permiso explícito verIngresos.
    final puedeVerCierres =
        isAdmin || (usuario?.tienePermiso(PermissionConstants.verIngresos) ?? false);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(usuario?.nombre ?? 'Usuario'),
              accountEmail: Text(usuario?.correo ?? 'sin-correo@loginova.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (usuario?.nombre.isNotEmpty ?? false)
                      ? usuario!.nombre[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: LoginovaColors.primary,
                  ),
                ),
              ),
              decoration: const BoxDecoration(color: LoginovaColors.primary),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildTile(context, '/home', Icons.dashboard, 'Dashboard'),
                  _buildTile(
                    context,
                    '/recogidas',
                    Icons.local_shipping,
                    'Recogidas',
                  ),
                  _buildTile(context, '/mapa', Icons.map, 'Mapa'),
                  _buildTile(
                    context,
                    '/historial-estados',
                    Icons.timeline,
                    'Historial de Estados',
                  ),
                  _buildTile(
                    context,
                    '/notificaciones',
                    Icons.notifications,
                    'Notificaciones',
                  ),
                  _buildTile(context, '/perfil', Icons.person, 'Mi Perfil'),
                  _buildTile(
                    context,
                    '/seguridad',
                    Icons.security,
                    'Seguridad',
                  ),
                  _buildTile(context, '/acerca', Icons.info, 'Acerca de'),
                  if (isAdmin) const Divider(height: 24),
                  if (isAdmin)
                    _buildTile(
                      context,
                      '/admin',
                      Icons.admin_panel_settings,
                      'Panel Admin',
                    ),
                  if (isAdmin)
                    _buildTile(
                      context,
                      '/auditoria',
                      Icons.fact_check,
                      'Auditoría',
                    ),
                  if (puedeVerCierres)
                    _buildTile(
                      context,
                      '/historial-cierres',
                      Icons.point_of_sale,
                      'Historial de cierres',
                    ),
                  // Sin "if (isAdmin)" a propósito: cualquier usuario
                  // autenticado (Operador, Subadministrador, etc.) puede
                  // necesitar soporte, no solo el Administrador de la
                  // empresa.
                  const Divider(height: 24),
                  ListTile(
                    leading: const Icon(
                      Icons.support_agent,
                      color: LoginovaColors.success,
                    ),
                    title: const Text('Contactar Soporte'),
                    subtitle: const Text('Escríbenos por WhatsApp'),
                    onTap: () => _contactarSoporte(context, usuario?.nombre),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: LoginovaColors.error),
              title: const Text('Cerrar sesión'),
              onTap: () async {
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
      ),
    );
  }

  /// Abre WhatsApp hacia Soporte con un mensaje prellenado identificando a
  /// quién escribe (su nombre y, si se pudo consultar, el de su empresa —
  /// cualquier rol: Administrador, Subadministrador, Operador, etc.), para
  /// que Soporte no tenga que preguntar quién es antes de poder ayudar.
  Future<void> _contactarSoporte(BuildContext context, String? nombreUsuario) async {
    Navigator.pop(context);

    final nombreEmpresa = await MiEmpresaService().obtenerNombreEmpresa();

    final identificacion = nombreEmpresa != null
        ? '${nombreUsuario ?? 'un usuario'} de $nombreEmpresa'
        : (nombreUsuario ?? 'un usuario de Loginova');

    final mensaje = 'Hola, soy $identificacion. Solicito soporte con Loginova.';

    final uri = Uri.parse(
      'https://wa.me/$_telefonoSoporte?text=${Uri.encodeComponent(mensaje)}',
    );

    final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  /// Construye un ítem de navegación del drawer. Cierra el drawer al
  /// tocar y solo navega si la ruta destino es distinta a la actual
  /// (evita apilar la misma pantalla dos veces).
  Widget _buildTile(
    BuildContext context,
    String route,
    IconData icon,
    String title,
  ) {
    return ListTile(
      selected: currentRoute == route,
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (currentRoute != route) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
