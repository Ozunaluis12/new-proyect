import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/evidencia.dart';
import '../services/evidencia_service.dart';

/// Pantalla independiente para capturar y subir una foto de evidencia
/// adicional asociada a una recogida (se usa, por ejemplo, desde el botón
/// "Agregar Evidencia" de [DetalleRecogidaScreen]). Es distinta de la foto
/// de evidencia que se toma dentro del flujo de cambio de estado
/// ([CambiarEstadoRecogidaScreen]), que es obligatoria para poder guardar.
class EvidenciaScreen extends StatefulWidget {
  final int? recogidaId;

  const EvidenciaScreen({super.key, this.recogidaId});

  @override
  State<EvidenciaScreen> createState() => _EvidenciaScreenState();
}

class _EvidenciaScreenState extends State<EvidenciaScreen> {
  File? imagen;
  bool guardando = false;

  final comentarioController = TextEditingController();

  /// Abre la cámara; si no está disponible (p.ej. web o permisos denegados)
  /// cae a la galería como alternativa para poder seguir el flujo.
  Future<void> tomarFoto() async {
    final picker = ImagePicker();

    try {
      final foto = await picker.pickImage(source: ImageSource.camera);

      if (foto != null && mounted) {
        setState(() {
          imagen = File(foto.path);
        });
      }
    } catch (_) {
      if (!mounted) return;

      try {
        final foto = await picker.pickImage(source: ImageSource.gallery);

        if (foto != null && mounted) {
          setState(() {
            imagen = File(foto.path);
          });
        }
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir la cámara. Puedes elegir una foto desde la galería.',
            ),
          ),
        );
      }
    }
  }

  /// Valida que exista una recogida asociada y una foto tomada, sube la
  /// evidencia al endpoint autenticado del backend y devuelve la URL de la
  /// foto guardada a la pantalla anterior (con una breve pausa para que el
  /// usuario alcance a ver el snackbar de confirmación antes de salir).
  Future<void> guardar() async {
    if (widget.recogidaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abre una recogida para agregar evidencia'),
        ),
      );
      return;
    }

    if (imagen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toma una foto antes de guardar')),
      );
      return;
    }

    setState(() => guardando = true);

    try {
      final evidenciaGuardada = await EvidenciaService().guardarEvidencia(
        Evidencia(
          id: 0,
          recogidaId: widget.recogidaId!,
          fotoUrl: '',
          comentario: comentarioController.text.trim(),
        ),
        foto: imagen!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evidencia guardada'),
          duration: Duration(seconds: 1),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;

        Navigator.pop(context, evidenciaGuardada.fotoUrl);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la evidencia')),
      );
    } finally {
      if (mounted) {
        setState(() => guardando = false);
      }
    }
  }

  @override
  void dispose() {
    comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evidencias')),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: tomarFoto,

                icon: const Icon(Icons.camera_alt),

                label: const Text('Tomar Foto'),
              ),
            ),

            const SizedBox(height: 20),

            if (imagen != null) Image.file(imagen!, height: 250),

            const SizedBox(height: 20),

            TextField(
              controller: comentarioController,

              maxLines: 4,

              decoration: const InputDecoration(
                labelText: 'Comentario',

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: guardando ? null : guardar,

                child: Text(guardando ? 'Guardando...' : 'Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
