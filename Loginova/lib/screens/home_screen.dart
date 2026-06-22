import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/recogida_provider.dart';
import '../themes/app_theme.dart';
import 'recogidas_screen.dart';
import 'perfil_screen.dart';

/// Dashboard principal que muestra estadísticas y opciones de navegación.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const DashboardView(),
    const RecogidasScreen(),
    const PerfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Cargar recogidas al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecogidaProvider>(context, listen: false).cargarRecogidas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            Provider.of<RecogidaProvider>(context, listen: false)
                .cargarRecogidas();
          }
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping),
            label: 'Recogidas',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

/// Vista del Dashboard con estadísticas y accesos rápidos
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = Provider.of<AuthProvider>(context).usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta de bienvenida
              _buildWelcomeCard(usuario?.nombre ?? 'Usuario'),
              const SizedBox(height: 24),

              // Estadísticas principales
              Text(
                'Estadísticas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildStatsGrid(context),
              const SizedBox(height: 24),

              // Accesos rápidos
              Text(
                'Accesos Rápidos',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la tarjeta de bienvenida
  Widget _buildWelcomeCard(String nombre) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [LoginovaColors.primary, LoginovaColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenido de vuelta',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '¿Listo para gestionar tus recogidas?',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la grilla de estadísticas
  Widget _buildStatsGrid(BuildContext context) {
    return Consumer<RecogidaProvider>(
      builder: (context, recogidaProvider, _) {
        final totalRecogidas = recogidaProvider.recogidas.length;
        final pendientes = recogidaProvider.recogidas
            .where((r) => r.estado.toLowerCase() == 'pendiente')
            .length;
        final completadas = recogidaProvider.recogidas
            .where((r) => r.estado.toLowerCase() == 'recogida')
            .length;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildStatCard(
              context,
              'Total Recogidas',
              totalRecogidas.toString(),
              Icons.local_shipping,
              LoginovaColors.primary,
            ),
            _buildStatCard(
              context,
              'Pendientes',
              pendientes.toString(),
              Icons.hourglass_empty,
              LoginovaColors.warning,
            ),
            _buildStatCard(
              context,
              'Completadas',
              completadas.toString(),
              Icons.check_circle,
              LoginovaColors.success,
            ),
            _buildStatCard(
              context,
              'En Progreso',
              (totalRecogidas - pendientes - completadas).toString(),
              Icons.autorenew,
              LoginovaColors.info,
            ),
          ],
        );
      },
    );
  }

  /// Construye una tarjeta individual de estadística
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye los accesos rápidos
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          context,
          'Nueva Recogida',
          'Crear una nueva recogida',
          Icons.add_circle,
          LoginovaColors.primary,
          () => Navigator.pushNamed(context, '/crear-recogida'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          'Ver Recogidas',
          'Gestiona todas tus recogidas',
          Icons.list,
          LoginovaColors.secondary,
          () => Navigator.pushNamed(context, '/recogidas'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          'Mapa de Recogidas',
          'Vista general por ubicaciones y estado',
          Icons.map,
          LoginovaColors.info,
          () => Navigator.pushNamed(context, '/mapa'),
        ),
      ],
    );
  }

  /// Construye un botón de acción rápida
  Widget _buildActionButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onPressed,
      ),
    );
  }

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
}
