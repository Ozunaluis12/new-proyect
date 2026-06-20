import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/evidencia.dart';
import '../services/evidencia_service.dart';

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

  Future<void> tomarFoto() async {
    final picker = ImagePicker();

    final foto = await picker.pickImage(source: ImageSource.camera);

    if (foto != null) {
      setState(() {
        imagen = File(foto.path);
      });
    }
  }

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
      await EvidenciaService().guardarEvidencia(
        Evidencia(
          id: 0,
          recogidaId: widget.recogidaId!,
          fotoUrl: imagen!.path,
          comentario: comentarioController.text.trim(),
        ),
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

        Navigator.pop(context, imagen!.path);
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
