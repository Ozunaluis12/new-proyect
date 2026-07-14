import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/usuario_service.dart';

/// Provider que gestiona la lista de usuarios del sistema.
class UsuariosProvider extends ChangeNotifier {
  final UsuarioService _service = UsuarioService();
  List<Usuario> _usuarios = [];
  bool _cargando = false;
  String? _error;

  List<Usuario> get usuarios => _usuarios;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Carga la lista de usuarios desde la API
  Future<void> cargarUsuarios() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _usuarios = await _service.obtenerUsuarios();
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Elimina un usuario por ID
  Future<void> eliminarUsuario(int id) async {
    try {
      await _service.eliminarUsuario(id);
      _usuarios.removeWhere((u) => u.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Crea un usuario con permisos.
  Future<Usuario> crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
    required List<String> permisos,
  }) async {
    final usuario = await _service.crearUsuario(
      nombre: nombre,
      correo: correo,
      password: password,
      rol: rol,
      permisos: permisos,
    );

    _usuarios.add(usuario);
    notifyListeners();
    return usuario;
  }

  /// Actualiza un usuario con permisos.
  Future<void> actualizarUsuario({
    required int id,
    required String nombre,
    required String correo,
    String? password,
    required String rol,
    required List<String> permisos,
  }) async {
    await _service.actualizarUsuario(
      id: id,
      nombre: nombre,
      correo: correo,
      password: password,
      rol: rol,
      permisos: permisos,
    );

    await cargarUsuarios();
  }
}
