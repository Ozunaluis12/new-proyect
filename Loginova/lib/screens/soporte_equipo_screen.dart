import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import '../services/soporte_equipo_service.dart';
import '../themes/app_theme.dart';
import '../widgets/responsive_center.dart';
import 'package:provider/provider.dart';

/// Administra las cuentas del propio equipo de Soporte: si con el tiempo son
/// varias personas atendiendo, cada una debería tener su propio login para
/// que la auditoría de acciones de Soporte quede atribuida a quien la hizo
/// de verdad, en vez de a una sola cuenta compartida.
class SoporteEquipoScreen extends StatefulWidget {
  const SoporteEquipoScreen({super.key});

  @override
  State<SoporteEquipoScreen> createState() => _SoporteEquipoScreenState();
}

class _SoporteEquipoScreenState extends State<SoporteEquipoScreen> {
  final _service = SoporteEquipoService();
  List<Usuario> _cuentas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final cuentas = await _service.obtenerCuentas();
      if (!mounted) return;
      setState(() => _cuentas = cuentas);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _crearCuenta() async {
    final nombreController = TextEditingController();
    final correoController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final creado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva cuenta de Soporte'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresa el nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el correo';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña inicial'),
                validator: (value) => (value == null || value.length < 8)
                    ? 'Mínimo 8 caracteres'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (creado != true || !mounted) return;

    try {
      await _service.crearCuenta(
        nombre: nombreController.text.trim(),
        correo: correoController.text.trim(),
        password: passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta de Soporte creada'),
          backgroundColor: LoginovaColors.success,
        ),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: LoginovaColors.error),
      );
    }
  }

  Future<void> _eliminarCuenta(Usuario cuenta) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar cuenta de Soporte'),
        content: Text('¿Eliminar la cuenta de "${cuenta.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: LoginovaColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    try {
      await _service.eliminarCuenta(cuenta.id);
      if (!mounted) return;
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: LoginovaColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final miId = Provider.of<AuthProvider>(context, listen: false).usuario?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Equipo de Soporte'), elevation: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearCuenta,
        icon: const Icon(Icons.person_add),
        label: const Text('Nueva cuenta'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ResponsiveCenter(
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _cuentas.length,
                  itemBuilder: (context, index) {
                    final cuenta = _cuentas[index];
                    final esMiCuenta = cuenta.id == miId;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.support_agent),
                        ),
                        title: Text(cuenta.nombre),
                        subtitle: Text(cuenta.correo),
                        trailing: esMiCuenta
                            ? const Chip(label: Text('Tú'))
                            : IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: LoginovaColors.error,
                                tooltip: 'Eliminar',
                                onPressed: () => _eliminarCuenta(cuenta),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
