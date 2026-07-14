import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../themes/app_theme.dart';

/// Drawer de navegación principal con accesos por rol.
class MenuDrawer extends StatelessWidget {
  final String currentRoute;

  const MenuDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final usuario = auth.usuario;
    final isAdmin = usuario?.rol.toLowerCase() == 'administrador';

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
