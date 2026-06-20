import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cliente.dart';
import '../models/recogida.dart';
import '../providers/auth_provider.dart';
import '../providers/recogida_provider.dart';
import '../services/cliente_service.dart';
import '../themes/app_theme.dart';

/// Pantalla profesional para crear una nueva recogida
class CrearRecogidaScreen extends StatefulWidget {
  const CrearRecogidaScreen({super.key});

  @override
  State<CrearRecogidaScreen> createState() => _CrearRecogidaScreenState();
}

class _CrearRecogidaScreenState extends State<CrearRecogidaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de cliente
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();
  
  // Controladores de recogida
  final _paquetesController = TextEditingController();
  final _observacionesController = TextEditingController();
  
  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _paquetesController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  /// Guarda la nueva recogida
  Future<void> _guardarRecogida() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _guardando = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final recogidaProvider =
          Provider.of<RecogidaProvider>(context, listen: false);

      if (auth.usuario == null) {
        throw Exception('Sesión inválida');
      }

      // Crear cliente
      final cliente = await ClienteService().crearCliente(
        Cliente(
          id: 0,
          nombre: _nombreController.text.trim(),
          telefono: _telefonoController.text.trim(),
          direccion: _direccionController.text.trim(),
          ciudad: _ciudadController.text.trim(),
        ),
      );

      // Crear recogida
      final cantidadPaquetes =
          int.tryParse(_paquetesController.text.trim()) ?? 1;
      
      final recogida = Recogida(
        id: 0,
        clienteId: cliente.id,
        usuarioId: auth.usuario!.id,
        estado: 'Pendiente',
        cantidadPaquetes: cantidadPaquetes,
        observaciones: _observacionesController.text.trim(),
        evidencias: const [],
      );

      await recogidaProvider.agregarRecogida(recogida);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recogida creada exitosamente'),
          backgroundColor: LoginovaColors.success,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: LoginovaColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Recogida'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de cliente
                _buildSectionTitle('Información del Cliente'),
                const SizedBox(height: 16),
                _buildClienteFields(),
                const SizedBox(height: 32),

                // Sección de recogida
                _buildSectionTitle('Detalles de la Recogida'),
                const SizedBox(height: 16),
                _buildRecogidaFields(),
                const SizedBox(height: 32),

                // Botones de acción
                _buildActionButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el título de una sección
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: LoginovaColors.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  /// Construye los campos de cliente
  Widget _buildClienteFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nombreController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Nombre del Cliente',
            hintText: 'Ej: Empresa XYZ',
            prefixIcon: const Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el nombre del cliente';
            }
            if (value.length < 3) {
              return 'El nombre debe tener al menos 3 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _telefonoController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Teléfono',
            hintText: 'Ej: +34 123 456 789',
            prefixIcon: const Icon(Icons.phone),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el teléfono';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _direccionController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Dirección',
            hintText: 'Ej: Calle Principal 123',
            prefixIcon: const Icon(Icons.location_on),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa la dirección';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ciudadController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Ciudad',
            hintText: 'Ej: Madrid',
            prefixIcon: const Icon(Icons.location_city),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa la ciudad';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Construye los campos de recogida
  Widget _buildRecogidaFields() {
    return Column(
      children: [
        TextFormField(
          controller: _paquetesController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Cantidad de Paquetes',
            hintText: 'Ej: 5',
            prefixIcon: const Icon(Icons.inventory_2),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa la cantidad de paquetes';
            }
            final cantidad = int.tryParse(value);
            if (cantidad == null || cantidad <= 0) {
              return 'Ingresa un número válido mayor a 0';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _observacionesController,
          textInputAction: TextInputAction.done,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Observaciones',
            hintText: 'Notas o instrucciones especiales...',
            prefixIcon: const Icon(Icons.note),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  /// Construye los botones de acción
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _guardando ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _guardando ? null : _guardarRecogida,
            child: _guardando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Guardar'),
          ),
        ),
      ],
    );
  }
}
      }
    }
  }

  @override
  void dispose() {
    clienteController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    ciudadController.dispose();
    paquetesController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Recogida')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: clienteController,
                decoration: const InputDecoration(
                  labelText: 'Cliente',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre del cliente';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Telefono',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el telefono del cliente';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: direccionController,
                decoration: const InputDecoration(
                  labelText: 'Direccion',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa la direccion';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: ciudadController,
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa la ciudad';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: paquetesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de paquetes',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa la cantidad de paquetes';
                  }
                  final parsed = int.tryParse(value);
                  if (parsed == null || parsed < 0) {
                    return 'Ingresa un numero valido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: observacionesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa una observacion';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: guardando ? null : guardar,

                  child: Text(guardando ? 'Guardando...' : 'Guardar Recogida'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
