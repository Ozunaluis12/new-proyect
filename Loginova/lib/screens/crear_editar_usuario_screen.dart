import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/permission_constants.dart';
import '../models/usuario.dart';
import '../providers/usuarios_provider.dart';

class CrearEditarUsuarioScreen extends StatefulWidget {
  final Usuario? usuario;

  const CrearEditarUsuarioScreen({super.key, this.usuario});

  @override
  State<CrearEditarUsuarioScreen> createState() =>
      _CrearEditarUsuarioScreenState();
}

class _CrearEditarUsuarioScreenState extends State<CrearEditarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  String _rolSeleccionado = 'Operador';
  final Set<String> _permisosSeleccionados = {};
  bool _guardando = false;

  bool get _editando => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    final usuario = widget.usuario;
    if (usuario != null) {
      _nombreController.text = usuario.nombre;
      _correoController.text = usuario.correo;
      _rolSeleccionado = usuario.rol == 'Subadministrador'
          ? 'Subadministrador'
          : 'Operador';
      _permisosSeleccionados.addAll(usuario.permisos);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text.trim().length < 8 && !_editando) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 8 caracteres'),
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final provider = Provider.of<UsuariosProvider>(context, listen: false);
      if (_editando) {
        await provider.actualizarUsuario(
          id: widget.usuario!.id,
          nombre: _nombreController.text.trim(),
          correo: _correoController.text.trim(),
          password: _passwordController.text.trim().isEmpty
              ? null
              : _passwordController.text.trim(),
          rol: _rolSeleccionado,
          permisos: _permisosSeleccionados.toList(),
        );
      } else {
        await provider.crearUsuario(
          nombre: _nombreController.text.trim(),
          correo: _correoController.text.trim(),
          password: _passwordController.text.trim(),
          rol: _rolSeleccionado,
          permisos: _permisosSeleccionados.toList(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el usuario: $e')),
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
        title: Text(_editando ? 'Editar Usuario' : 'Nuevo Usuario'),
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
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el nombre'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correoController,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el correo';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _editando
                        ? 'Nueva contraseña (opcional)'
                        : 'Contraseña',
                  ),
                  validator: (value) {
                    if (_editando) {
                      return null;
                    }
                    if (value == null || value.trim().length < 8) {
                      return 'Ingresa una contraseña de al menos 8 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _rolSeleccionado,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Operador',
                      child: Text('Operador'),
                    ),
                    DropdownMenuItem(
                      value: 'Subadministrador',
                      child: Text('Subadministrador'),
                    ),
                  ],
                  onChanged: _guardando
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _rolSeleccionado = value);
                        },
                ),
                const SizedBox(height: 24),
                Text(
                  'Permisos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...PermissionConstants.all.map(
                  (permiso) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _permisosSeleccionados.contains(permiso),
                    title: Text(PermissionConstants.labels[permiso] ?? permiso),
                    onChanged: _guardando
                        ? null
                        : (checked) {
                            setState(() {
                              if (checked == true) {
                                _permisosSeleccionados.add(permiso);
                              } else {
                                _permisosSeleccionados.remove(permiso);
                              }
                            });
                          },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    child: Text(_guardando ? 'Guardando...' : 'Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
