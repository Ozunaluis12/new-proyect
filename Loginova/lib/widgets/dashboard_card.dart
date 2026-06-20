import 'package:flutter/material.dart';

/// Widget que muestra una tarjeta del dashboard con titulo, valor e icono.
class DashboardCard extends StatelessWidget {
  /// Titulo descriptivo de la tarjeta.
  final String titulo;

  /// Valor principal a mostrar en la tarjeta.
  final String valor;

  /// Icono a mostrar en la tarjeta.
  final IconData icono;

  const DashboardCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 40),
            const SizedBox(height: 10),
            Text(
              valor,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(titulo),
          ],
        ),
      ),
    );
  }
}
