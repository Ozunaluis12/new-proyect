import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../constants/permission_constants.dart';
import '../models/recogida.dart';
import '../providers/auth_provider.dart';
import '../services/recogida_service.dart';
import '../widgets/llamar_cliente_button.dart';
import 'registrar_ingreso_screen.dart';

/// Pantalla central del flujo operativo: el operador cambia el estado de una
/// recogida (Pendiente/Recogida/Cancelada), sube la foto de evidencia
/// obligatoria y, si corresponde, registra el dinero cobrado. El backend
/// reasigna aquí mismo el "dueño" de la recogida y el responsable del dinero
/// a quien hace este cambio de estado (no a quien creó la recogida
/// originalmente); esta pantalla es la que dispara esa reasignación.
class CambiarEstadoRecogidaScreen extends StatefulWidget {
  final Recogida recogida;

  const CambiarEstadoRecogidaScreen({super.key, required this.recogida});

  @override
  State<CambiarEstadoRecogidaScreen> createState() =>
      _CambiarEstadoRecogidaScreenState();
}

class _CambiarEstadoRecogidaScreenState
    extends State<CambiarEstadoRecogidaScreen> {
  static const List<String> _estadosPermitidos = [
    'Pendiente',
    'Recogida',
    'Cancelada',
  ];

  final _comentarioController = TextEditingController();
  final _paquetesController = TextEditingController();
  final _service = RecogidaService();

  File? _imagen;
  late String _estadoSeleccionado;
  bool _dineroRecibido = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Si el estado actual de la recogida no está entre los permitidos aquí
    // (p.ej. viene como "Asignada" o "En Ruta"), se arranca en "Pendiente"
    // como valor seguro por defecto.
    _estadoSeleccionado = _estadosPermitidos.contains(widget.recogida.estado)
        ? widget.recogida.estado
        : 'Pendiente';
    if (widget.recogida.cantidadPaquetes > 0) {
      _paquetesController.text = widget.recogida.cantidadPaquetes.toString();
    }
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _paquetesController.dispose();
    super.dispose();
  }

  /// Abre la cámara para la foto de evidencia; si falla (p.ej. sin permiso
  /// de cámara o en web sin soporte), cae a la galería como alternativa.
  Future<void> _tomarFoto() async {
    final picker = ImagePicker();

    try {
      final foto = await picker.pickImage(source: ImageSource.camera);

      if (foto != null && mounted) {
        setState(() {
          _imagen = File(foto.path);
        });
      }
    } catch (_) {
      if (!mounted) return;

      try {
        final foto = await picker.pickImage(source: ImageSource.gallery);

        if (foto != null && mounted) {
          setState(() {
            _imagen = File(foto.path);
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

  /// Valida y envía el cambio de estado al backend. Contiene las reglas de
  /// negocio clave de esta pantalla: el dinero solo se puede registrar al
  /// completar la recogida (estado "Recogida"), la foto de evidencia es
  /// obligatoria siempre, y la cantidad de paquetes es obligatoria solo al
  /// completar (porque recién ahí el operador los cuenta con certeza).
  Future<void> _guardar() async {
    double? montoCobrado;
    String? formaPago;
    File? fotoParaEvidencia;

    if (_dineroRecibido) {
      if (_estadoSeleccionado.toLowerCase() != 'recogida') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solo puedes registrar dinero al completar la recogida',
            ),
          ),
        );
        return;
      }

      // Delega a una pantalla dedicada para capturar monto, forma de pago y
      // (opcionalmente) su propia foto del comprobante de pago.
      final ingreso = await Navigator.push<IngresoDraft>(
        context,
        MaterialPageRoute(builder: (_) => const RegistrarIngresoScreen()),
      );

      if (ingreso == null) {
        return;
      }

      montoCobrado = ingreso.monto;
      formaPago = ingreso.formaPago;
      fotoParaEvidencia = ingreso.foto;
    }

    if (_imagen == null && fotoParaEvidencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes tomar una foto antes de guardar')),
      );
      return;
    }

    int? cantidadPaquetes;
    if (_estadoSeleccionado.toLowerCase() == 'recogida') {
      cantidadPaquetes = int.tryParse(_paquetesController.text.trim());
      if (cantidadPaquetes == null || cantidadPaquetes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Indica cuántos paquetes recogiste antes de guardar',
            ),
          ),
        );
        return;
      }
    } else {
      cantidadPaquetes = int.tryParse(_paquetesController.text.trim());
    }

    setState(() => _guardando = true);

    try {
      // La foto del comprobante de pago (si existe) reemplaza a la foto de
      // evidencia general, para no exigir subir dos imágenes distintas.
      final actualizada = await _service.actualizarEstadoRecogida(
        widget.recogida.id,
        estado: _estadoSeleccionado,
        foto: fotoParaEvidencia ?? _imagen,
        dineroRecibido: _dineroRecibido,
        montoCobrado: montoCobrado,
        formaPago: formaPago,
        comentario: _comentarioController.text.trim(),
        cantidadPaquetes: cantidadPaquetes,
      );

      if (!mounted) return;
      Navigator.pop(context, actualizada);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el estado')),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Provider.of<AuthProvider>(context).usuario;
    final puedeRegistrarIngresos =
        usuario?.tienePermiso(PermissionConstants.registrarIngresos) ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Estado y evidencia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LlamarClienteButton(
              nombreCliente: widget.recogida.clienteNombre,
              telefono: widget.recogida.clienteTelefono,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _estadoSeleccionado,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: _estadosPermitidos
                  .map(
                    (estado) =>
                        DropdownMenuItem(value: estado, child: Text(estado)),
                  )
                  .toList(),
              onChanged: _guardando
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _estadoSeleccionado = value);
                    },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _paquetesController,
              enabled: !_guardando,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _estadoSeleccionado.toLowerCase() == 'recogida'
                    ? 'Cantidad de paquetes (obligatorio)'
                    : 'Cantidad de paquetes',
                hintText: 'Cuéntalos al recibirlos',
                prefixIcon: const Icon(Icons.inventory_2),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _guardando ? null : _tomarFoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar foto de soporte'),
            ),
            const SizedBox(height: 16),
            if (_imagen != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imagen!, height: 240, fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
            ],
            if (puedeRegistrarIngresos) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dinero recibido'),
                value: _dineroRecibido,
                onChanged: _guardando
                    ? null
                    : (value) {
                        setState(() => _dineroRecibido = value);
                      },
              ),
              if (_dineroRecibido)
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(
                    'Al guardar pasarás a la vista para registrar cantidad y forma de pago.',
                  ),
                ),
            ],
            TextField(
              controller: _comentarioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Comentario',
                hintText:
                    'Escribe aquí la cantidad de paquetes y observaciones',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
