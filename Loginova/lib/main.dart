import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/recogida_provider.dart';
import 'themes/app_theme.dart';

/// Punto de entrada de la aplicación Loginova.
void main() {
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
        ChangeNotifierProvider(create: (_) => RecogidaProvider()),
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