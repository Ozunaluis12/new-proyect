import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/ingresos_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/usuarios_provider.dart';
import 'providers/recogida_provider.dart';
import 'providers/location_provider.dart';
import 'providers/maps_provider.dart';
import 'providers/proximity_provider.dart';
import 'themes/app_theme.dart';
import 'services/firebase_service.dart';
import 'services/maps_service.dart';
import 'services/api_service.dart';
import 'constants/app_constants.dart';

/// Punto de entrada de la aplicación Loginova: registra los servicios e
/// inicializaciones que deben completarse antes de mostrar cualquier
/// pantalla (token de sesión, Firebase, Google Maps).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga token de sesión antes de inicializar Firebase para que
  // AuthProvider pueda saber de entrada si ya hay una sesión activa
  // (evita mostrar el login brevemente aunque el usuario ya esté logueado).
  await ApiService.loadToken();

  // Inicializa Firebase (usado para notificaciones push, etc.).
  await FirebaseService.initialize();

  // Configura Google Maps API Key si fue inyectada por entorno.
  // Nota: la app usa OpenStreetMap/Mapbox como mapa visual principal;
  // esta key solo aplicaría si se reactivan llamadas a la API de Google.
  if (AppConstants.hasGoogleMapsApiKey) {
    MapsService.setApiKey(AppConstants.googleMapsApiKey);
  }

  runApp(const LoginovaApp());
}

/// Widget raíz de la aplicación que configura MultiProvider y MaterialApp.
class LoginovaApp extends StatelessWidget {
  const LoginovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      /// Proveedores de estado global para autenticación, usuarios,
      /// recogidas, ingresos, ubicación en tiempo real, mapas y
      /// proximidad del operador; se registran aquí para que estén
      /// disponibles en toda la app vía Provider.of/context.watch.
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => IngresosProvider()),
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => UsuariosProvider()),
        ChangeNotifierProvider(create: (_) => RecogidaProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => MapsProvider()),
        ChangeNotifierProvider(create: (_) => ProximityProvider()),
      ],

      /// Configuración de la aplicación con rutas nombradas.
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Loginova',
        theme: AppTheme.lightTheme(),
        initialRoute: '/',
        routes: AppRoutes.routes,
      ),
    );
  }
}
