import 'package:flutter/material.dart';

import '../themes/app_theme.dart';
import '../widgets/menu_drawer.dart';

class AcercaScreen extends StatelessWidget {
  const AcercaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MenuDrawer(currentRoute: '/acerca'),
      appBar: AppBar(title: const Text('Acerca de Loginova')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [
                        LoginovaColors.primary,
                        LoginovaColors.primaryDark,
                      ],
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOGINOVA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Gestión logística y recolección en tiempo real.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _infoCard(
                context,
                icon: Icons.info_outline,
                title: 'Versión',
                description: '1.0.0',
              ),
              _infoCard(
                context,
                icon: Icons.code,
                title: 'Stack',
                description: 'Flutter + ASP.NET Core + PostgreSQL',
              ),
              _infoCard(
                context,
                icon: Icons.policy,
                title: 'Privacidad',
                description:
                    'Los datos operativos son utilizados solo para trazabilidad y operación logística.',
              ),
              _infoCard(
                context,
                icon: Icons.support_agent,
                title: 'Soporte',
                description: 'soporte@loginova.com',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: LoginovaColors.primary),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}
