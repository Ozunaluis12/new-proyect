import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
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
import '../screens/historial_cierres_screen.dart';
import '../screens/soporte_panel_screen.dart';

/// Definición de todas las rutas nombradas de la aplicación, incluyendo
/// los "guards" que restringen el acceso a ciertas pantallas según si
/// hay sesión iniciada o según el rol del usuario logueado.
class AppRoutes {
  /// Envuelve una pantalla para que solo sea accesible con sesión
  /// iniciada; si no hay sesión, redirige a la pantalla de login en
  /// lugar de la pantalla protegida.
  static WidgetBuilder _authGuard(WidgetBuilder childBuilder) {
    return (context) {
      final auth = Provider.of<AuthProvider>(context);
      if (!auth.logueado) {
        return const LoginScreen();
      }
      return childBuilder(context);
    };
  }

  /// Envuelve una pantalla para que solo sea accesible por el rol
  /// Administrador; sin sesión redirige a login, y con sesión pero sin
  /// rol de administrador muestra una pantalla de acceso denegado en
  /// vez de la pantalla protegida.
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

  /// Envuelve una pantalla para que solo sea accesible por el rol Soporte
  /// (administra las empresas clientes del sistema multi-tenant, no
  /// pertenece a ninguna empresa). Sin sesión redirige a login; con sesión
  /// pero sin rol Soporte muestra acceso denegado, para que ni siquiera el
  /// Administrador de una empresa pueda ver o tocar el panel de Soporte.
  static WidgetBuilder _soporteGuard(WidgetBuilder childBuilder) {
    return (context) {
      final auth = Provider.of<AuthProvider>(context);
      if (!auth.logueado) {
        return const LoginScreen();
      }

      final esSoporte = auth.usuario?.rol.toLowerCase() == 'soporte';
      if (!esSoporte) {
        return Scaffold(
          appBar: AppBar(title: const Text('Acceso Denegado')),
          body: const Center(
            child: Text('Solo Soporte puede acceder a esta vista.'),
          ),
        );
      }

      return childBuilder(context);
    };
  }

  /// Mapa de rutas disponibles en la aplicación. Las rutas de
  /// autenticación ('/', '/forgot') quedan abiertas sin guard; el resto
  /// exige sesión iniciada (_authGuard) y algunas, además, rol de
  /// Administrador (_adminGuard) o de Soporte (_soporteGuard). No hay
  /// registro público: toda cuenta nueva la crea un Administrador (desde
  /// su panel de usuarios) o Soporte (el primer admin de cada empresa).
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const LoginScreen(),
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
    '/historial-cierres': _authGuard(
      (context) => const HistorialCierresScreen(),
    ),
    '/soporte': _soporteGuard((context) => const SoportePanelScreen()),
  };
}
