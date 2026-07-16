import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

/// Provider que gestiona el estado de autenticación de la aplicación.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _logueado = false;
  bool _cargando = false;
  Usuario? _usuario;
  String? _error;

  bool get logueado => _logueado;
  bool get cargando => _cargando;
  Usuario? get usuario => _usuario;
  String? get error => _error;

  AuthProvider() {
    cargarSesion();
  }

  Future<void> cargarSesion() async {
    await ApiService.loadToken();
    final usuarioJson = await ApiService.loadUsuarioJson();

    if (ApiService.token != null && usuarioJson != null) {
      _usuario = Usuario.fromJson(jsonDecode(usuarioJson));
      _logueado = true;
      notifyListeners();
    }
  }

  /// Intenta iniciar sesión con correo y contraseña.
  /// Retorna true si el inicio de sesión fue exitoso.
  Future<bool> login(String correo, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(correo, password);
    _cargando = false;

    if (result == null) {
      _logueado = false;
      _usuario = null;
      _error = 'Correo o contraseña incorrectos';
      notifyListeners();
      return false;
    }

    _logueado = true;
    _usuario = result.usuario;
    // Registra/actualiza el token FCM en el backend tras iniciar sesión
    await FirebaseService.updateFCMToken();
    notifyListeners();
    return true;
  }

  /// Registra un usuario nuevo y actualiza el estado local si tiene éxito.
  Future<bool> register(String nombre, String correo, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    final result = await _authService.register(nombre, correo, password);
    _cargando = false;

    if (result == null) {
      _logueado = false;
      _usuario = null;
      _error = 'No se pudo registrar el usuario';
      notifyListeners();
      return false;
    }

    _logueado = true;
    _usuario = result.usuario;
    notifyListeners();
    return true;
  }

  /// Solicita el código de recuperación de contraseña al correo indicado.
  Future<bool> solicitarCodigoRecuperacion(String correo) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    final success = await _authService.forgotPassword(correo);
    _cargando = false;

    if (!success) {
      _error = 'No se pudo enviar el código. Intenta nuevamente.';
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Verifica el código recibido y establece la nueva contraseña.
  Future<bool> resetPassword(
    String correo,
    String codigo,
    String nuevaPassword,
  ) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    final success = await _authService.resetPassword(
      correo,
      codigo,
      nuevaPassword,
    );
    _cargando = false;

    if (!success) {
      _error = 'Código inválido o expirado';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<void> logout() async {
    await ApiService.clearSession();
    _logueado = false;
    _usuario = null;

    notifyListeners();
  }
}
