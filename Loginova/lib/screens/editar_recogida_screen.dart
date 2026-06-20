import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recogida.dart';
import '../providers/recogida_provider.dart';

/// Pantalla que permite editar los datos de una recogida existente.
class EditarRecogidaScreen extends StatefulWidget {
  final Recogida recogida;

  const EditarRecogidaScreen({super.key, required this.recogida});

  @override
  State<EditarRecogidaScreen> createState() => _EditarRecogidaScreenState();
}

class _EditarRecogidaScreenState extends State<EditarRecogidaScreen> {
  late TextEditingController estadoController;
  late TextEditingController paquetesController;
  late TextEditingController observacionesController;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    estadoController = TextEditingController(text: widget.recogida.estado);
    paquetesController = TextEditingController(
      text: widget.recogida.cantidadPaquetes.toString(),
    );
    observacionesController = TextEditingController(
      text: widget.recogida.observaciones,
    );
  }

  @override
  void dispose() {
    estadoController.dispose();
    paquetesController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  Future<void> guardarCambios() async {
    if (estadoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El estado no puede quedar vacío')),
      );
      return;
    }

    final cantidad = int.tryParse(paquetesController.text.trim());
    if (cantidad == null || cantidad < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad de paquetes inválida')),
      );
      return;
    }

    setState(() => guardando = true);

    final actualizado = Recogida(
      id: widget.recogida.id,
      clienteId: widget.recogida.clienteId,
      usuarioId: widget.recogida.usuarioId,
      estado: estadoController.text.trim(),
      cantidadPaquetes: cantidad,
      observaciones: observacionesController.text.trim(),
      evidencias: widget.recogida.evidencias,
    );

    try {
      await Provider.of<RecogidaProvider>(
        context,
        listen: false,
      ).actualizarRecogida(actualizado);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la recogida')),
      );
    } finally {
      if (mounted) {
        setState(() => guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Recogida')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: estadoController,
              decoration: const InputDecoration(labelText: 'Estado'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: paquetesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad de paquetes',
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: observacionesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: guardando ? null : guardarCambios,
                child: Text(guardando ? 'Guardando...' : 'Guardar Cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
