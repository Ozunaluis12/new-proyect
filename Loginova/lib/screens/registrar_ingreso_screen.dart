import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class IngresoDraft {
  final double monto;
  final String formaPago;
  final File? foto;

  const IngresoDraft({required this.monto, required this.formaPago, this.foto});
}

class RegistrarIngresoScreen extends StatefulWidget {
  const RegistrarIngresoScreen({super.key});

  @override
  State<RegistrarIngresoScreen> createState() => _RegistrarIngresoScreenState();
}

class _RegistrarIngresoScreenState extends State<RegistrarIngresoScreen> {
  static const List<String> _formasPago = ['Efectivo', 'Transferencia'];

  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  String _formaPago = 'Efectivo';
  File? _imagen;

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

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

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      IngresoDraft(
        monto: double.parse(_montoController.text.trim()),
        formaPago: _formaPago,
        foto: _imagen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ingreso')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _montoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad recibida',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final monto = double.tryParse((value ?? '').trim());
                    if (monto == null || monto <= 0) {
                      return 'Ingresa una cantidad válida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _formaPago,
                  decoration: const InputDecoration(
                    labelText: 'Forma de pago',
                    border: OutlineInputBorder(),
                  ),
                  items: _formasPago
                      .map(
                        (formaPago) => DropdownMenuItem(
                          value: formaPago,
                          child: Text(formaPago),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _formaPago = value);
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _tomarFoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar foto de la evidencia del dinero'),
                ),
                const SizedBox(height: 16),
                if (_imagen != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imagen!, height: 220, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 20),
                ],
                ElevatedButton(
                  onPressed: _guardar,
                  child: const Text('Guardar ingreso'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
