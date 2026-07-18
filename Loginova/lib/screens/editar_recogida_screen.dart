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
  DateTime? _horarioLimite;
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
    _horarioLimite = widget.recogida.fechaProgramada;
  }

  /// Abre selector de fecha y hora para el horario límite de la recogida.
  Future<void> _seleccionarHorarioLimite() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _horarioLimite ?? ahora,
      firstDate: ahora.subtract(const Duration(days: 1)),
      lastDate: ahora.add(const Duration(days: 365)),
    );
    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: _horarioLimite != null
          ? TimeOfDay.fromDateTime(_horarioLimite!)
          : TimeOfDay.fromDateTime(ahora.add(const Duration(hours: 1))),
    );
    if (hora == null || !mounted) return;

    setState(() {
      _horarioLimite = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  /// Formatea una fecha/hora local como "dd/MM/yyyy HH:mm" sin depender del
  /// paquete intl.
  String _formatearFechaHora(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final hh = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha.year} $hh:$min';
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

    // Se copian todos los campos que este formulario no edita (ubicación,
    // dinero cobrado, etc.) para no borrarlos accidentalmente: el backend
    // reemplaza la recogida completa con lo que se le envíe en Update.
    final actualizado = Recogida(
      id: widget.recogida.id,
      clienteId: widget.recogida.clienteId,
      clienteNombre: widget.recogida.clienteNombre,
      clienteTelefono: widget.recogida.clienteTelefono,
      usuarioId: widget.recogida.usuarioId,
      usuarioNombre: widget.recogida.usuarioNombre,
      estado: _estadoSeleccionado,
      cantidadPaquetes: cantidad,
      observaciones: observacionesController.text.trim(),
      evidencias: widget.recogida.evidencias,
      dineroRecibido: widget.recogida.dineroRecibido,
      montoCobrado: widget.recogida.montoCobrado,
      latitud: widget.recogida.latitud,
      longitud: widget.recogida.longitud,
      fechaCreacion: widget.recogida.fechaCreacion,
      fechaProgramada: _horarioLimite,
      fechaRecogida: widget.recogida.fechaRecogida,
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Horario límite'),
              subtitle: Text(
                _horarioLimite != null
                    ? _formatearFechaHora(_horarioLimite!)
                    : 'Sin horario definido',
              ),
              trailing: _horarioLimite != null
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Quitar horario',
                      onPressed: guardando
                          ? null
                          : () => setState(() => _horarioLimite = null),
                    )
                  : null,
              onTap: guardando ? null : _seleccionarHorarioLimite,
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
