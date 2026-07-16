import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/permission_constants.dart';
import '../models/recogida.dart';
import '../providers/auth_provider.dart';
import '../providers/recogida_provider.dart';

/// Pantalla que permite editar los datos de una recogida existente.
class EditarRecogidaScreen extends StatefulWidget {
  final Recogida recogida;

  const EditarRecogidaScreen({super.key, required this.recogida});

  @override
  State<EditarRecogidaScreen> createState() => _EditarRecogidaScreenState();
}

class _EditarRecogidaScreenState extends State<EditarRecogidaScreen> {
  static const List<String> _estadosPermitidos = [
    'Pendiente',
    'Asignada',
    'En Ruta',
    'Recogida',
    'Cancelada',
  ];

  late String _estadoSeleccionado;
  late TextEditingController paquetesController;
  late TextEditingController observacionesController;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = _estadosPermitidos.contains(widget.recogida.estado)
        ? widget.recogida.estado
        : 'Pendiente';
    paquetesController = TextEditingController(
      text: widget.recogida.cantidadPaquetes.toString(),
    );
    observacionesController = TextEditingController(
      text: widget.recogida.observaciones ?? '',
    );
  }

  @override
  void dispose() {
    paquetesController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  /// Guarda los cambios de la recogida. A diferencia del cambio de estado
  /// desde [CambiarEstadoRecogidaScreen], esta edición NO reasigna el
  /// usuarioId (operador dueño): se conserva el `widget.recogida.usuarioId`
  /// original porque aquí solo se corrigen datos, no se ejecuta el flujo
  /// operativo de "tomar" la recogida.
  Future<void> guardarCambios() async {
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
      estado: _estadoSeleccionado,
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
      Navigator.pop(context, actualizado);
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
    final usuario = Provider.of<AuthProvider>(context).usuario;
    final puedeEditar =
        usuario?.tienePermiso(PermissionConstants.editarRecogidas) ?? false;

    if (!puedeEditar) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Recogida')),
        body: const Center(
          child: Text('No tienes permiso para editar recogidas.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Recogida')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _estadoSeleccionado,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: _estadosPermitidos
                  .map(
                    (estado) =>
                        DropdownMenuItem(value: estado, child: Text(estado)),
                  )
                  .toList(),
              onChanged: guardando
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _estadoSeleccionado = value);
                    },
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
