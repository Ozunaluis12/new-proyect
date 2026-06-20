import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../themes/app_theme.dart';

/// Pantalla profesional que muestra y gestiona el perfil del usuario autenticado.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  /// Cierra la sesión del usuario
  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Provider.of<AuthProvider>(context).usuario;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil'), elevation: 0),
      body: usuario == null
          ? _buildNoUsuario()
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de perfil con avatar
                    _buildProfileCard(usuario),
                    const SizedBox(height: 32),

                    // Sección de información
                    _buildSectionTitle('Información Personal'),
                    const SizedBox(height: 12),
                    _buildInfoSection(usuario),
                    const SizedBox(height: 32),

                    // Sección de configuración
                    _buildSectionTitle('Configuración'),
                    const SizedBox(height: 12),
                    _buildSettingsSection(context),
                    const SizedBox(height: 32),

                    // Botón de cerrar sesión
                    _buildLogoutButton(context),
                  ],
                ),
              ),
            ),
    );
  }

  /// Construye el widget cuando no hay usuario
  Widget _buildNoUsuario() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: LoginovaColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay usuario autenticado',
            style: TextStyle(fontSize: 18, color: LoginovaColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Construye la tarjeta de perfil
  Widget _buildProfileCard(dynamic usuario) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [LoginovaColors.primary, LoginovaColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // Nombre
            Text(
              usuario.nombre ?? 'Nombre no disponible',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Rol
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                usuario.rol ?? 'Sin rol',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el título de una sección
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: LoginovaColors.primary,
      ),
    );
  }

  /// Construye la sección de información
  Widget _buildInfoSection(dynamic usuario) {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.email,
          label: 'Correo Electrónico',
          value: usuario.correo ?? 'No disponible',
          color: LoginovaColors.info,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.badge,
          label: 'ID de Usuario',
          value: '#${usuario.id}',
          color: LoginovaColors.secondary,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.security,
          label: 'Rol',
          value: usuario.rol ?? 'No disponible',
          color: LoginovaColors.success,
        ),
      ],
    );
  }

  /// Construye una tarjeta de información
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: LoginovaColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: LoginovaColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la sección de configuración
  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notificaciones',
            subtitle: 'Gestiona las notificaciones',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Seguridad',
            subtitle: 'Cambiar contraseña',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'Acerca de',
            subtitle: 'Versión 1.0.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  /// Construye una opción de configuración
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: LoginovaColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  /// Construye el botón de cerrar sesión
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => _cerrarSesion(context),
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar Sesión'),
        style: ElevatedButton.styleFrom(
          backgroundColor: LoginovaColors.error,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
