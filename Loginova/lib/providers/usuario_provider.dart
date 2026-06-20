import 'package:flutter/material.dart';

import '../models/usuario.dart';

/// Provider que gestiona el estado del usuario actual en la sesión.
class UsuarioProvider extends ChangeNotifier {
  Usuario? _usuario;

  Usuario? get usuario => _usuario;

  /// Establece el usuario actual en el estado.
  void setUsuario(Usuario usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  /// Limpia el usuario actual cuando se cierra la sesión.
  void limpiar() {
    _usuario = null;
    notifyListeners();
  }
}
