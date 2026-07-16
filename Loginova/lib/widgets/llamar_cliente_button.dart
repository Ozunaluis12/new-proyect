import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../themes/app_theme.dart';

/// Botón que permite llamar directamente al cliente de una recogida.
/// No se muestra si no hay un teléfono registrado.
class LlamarClienteButton extends StatelessWidget {
  final String? nombreCliente;
  // Teléfono que ya viene resuelto en el modelo Recogida (clienteTelefono),
  // no se consulta aparte.
  final String? telefono;

  const LlamarClienteButton({
    super.key,
    required this.nombreCliente,
    required this.telefono,
  });

  /// Abre el marcador telefónico del dispositivo con el número del
  /// cliente usando el esquema `tel:`. Muestra un aviso si el sistema
  /// no pudo iniciar la llamada (p. ej. no hay app de teléfono, como
  /// puede pasar en la versión web).
  Future<void> _llamar(BuildContext context) async {
    final numero = telefono?.trim() ?? '';
    if (numero.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: numero);
    final pudoAbrir = await launchUrl(uri);

    if (!pudoAbrir && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo iniciar la llamada a $numero')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final numero = telefono?.trim() ?? '';
    if (numero.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: LoginovaColors.primary.withValues(alpha: 0.1),
          child: Icon(Icons.person, color: LoginovaColors.primary),
        ),
        title: Text(
          (nombreCliente == null || nombreCliente!.isEmpty)
              ? 'Cliente'
              : nombreCliente!,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(numero),
        trailing: ElevatedButton.icon(
          onPressed: () => _llamar(context),
          icon: const Icon(Icons.call, size: 18),
          label: const Text('Llamar'),
        ),
      ),
    );
  }
}
