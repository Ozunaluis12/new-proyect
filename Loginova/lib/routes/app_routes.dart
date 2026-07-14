import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/recogidas_screen.dart';
import '../screens/crear_recogida_screen.dart';
import '../screens/mapa_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/perfil_screen.dart';
import '../screens/notificaciones_screen.dart';
import '../screens/seguridad_screen.dart';
import '../screens/acerca_screen.dart';
import '../screens/auditoria_screen.dart';
import '../screens/historial_estados_screen.dart';

/// Definición de todas las rutas nombradas de la aplicación.
class AppRoutes {
  static WidgetBuilder _authGuard(WidgetBuilder childBuilder) {
    return (context) {
      final auth = Provider.of<AuthProvider>(context);
      if (!auth.logueado) {
        return const LoginScreen();
      }
      return childBuilder(context);
    };
  }

  static WidgetBuilder _adminGuard(WidgetBuilder childBuilder) {
    return (context) {
      final auth = Provider.of<AuthProvider>(context);
      if (!auth.logueado) {
        return const LoginScreen();
      }

      final isAdmin = auth.usuario?.rol.toLowerCase() == 'administrador';
      if (!isAdmin) {
        return Scaffold(
          appBar: AppBar(title: const Text('Acceso Denegado')),
          body: const Center(
            child: Text('Solo administradores pueden acceder a esta vista.'),
          ),
        );
      }

      return childBuilder(context);
    };
  }

  /// Mapa de rutas disponibles en la aplicación.
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/forgot': (context) => const ForgotPasswordScreen(),
    '/home': _authGuard((context) => const HomeScreen()),
    '/recogidas': _authGuard((context) => const RecogidasScreen()),
    '/crear-recogida': _authGuard((context) => const CrearRecogidaScreen()),
    '/mapa': _authGuard((context) => const MapaScreen()),
    '/perfil': _authGuard((context) => const PerfilScreen()),
    '/notificaciones': _authGuard((context) => const NotificacionesScreen()),
    '/seguridad': _authGuard((context) => const SeguridadScreen()),
    '/acerca': _authGuard((context) => const AcercaScreen()),
    '/historial-estados': _authGuard(
      (context) => const HistorialEstadosScreen(),
    ),
    '/admin': _adminGuard((context) => const AdminDashboardScreen()),
    '/auditoria': _adminGuard((context) => const AuditoriaScreen()),
  };
}
