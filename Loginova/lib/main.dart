import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/usuarios_provider.dart';
import 'providers/recogida_provider.dart';
import 'providers/location_provider.dart';
import 'providers/maps_provider.dart';
import 'themes/app_theme.dart';
import 'services/firebase_service.dart';
import 'services/maps_service.dart';
import 'constants/app_constants.dart';

/// Punto de entrada de la aplicación Loginova.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Firebase
  await FirebaseService.initialize();
  
  // Configura Google Maps API Key si fue inyectada por entorno.
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
      /// Proveedores de estado global para autenticación, usuarios y recogidas.
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => UsuariosProvider()),
        ChangeNotifierProvider(create: (_) => RecogidaProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => MapsProvider()),
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
