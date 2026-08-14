import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/geocoding_service.dart';
import '../services/mi_empresa_service.dart';

/// Provider que gestiona el estado de autenticación de la aplicación.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final MiEmpresaService _miEmpresaService = MiEmpresaService();

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

  /// Restaura la sesión guardada al arrancar la app (token + usuario desde
  /// almacenamiento seguro), evitando pedir login de nuevo en cada apertura.
  Future<void> cargarSesion() async {
    await ApiService.loadToken();
    final usuarioJson = await ApiService.loadUsuarioJson();

    if (ApiService.token != null && usuarioJson != null) {
      _usuario = Usuario.fromJson(jsonDecode(usuarioJson));
      _logueado = true;
      notifyListeners();
      // No se espera: no debe demorar el arranque de la app si la red está
      // lenta. Mientras tanto el buscador de direcciones sigue funcionando
      // sin sesgo de ciudad (solo restringido a Colombia).
      _aplicarCiudadDeOperacion();
    }
  }

  /// Carga la ciudad de operación de la empresa del usuario logueado y la
  /// fija como sesgo por defecto del buscador de direcciones (en vez de una
  /// ciudad fija en el código), para que las sugerencias sean relevantes
  /// desde la primera búsqueda aunque el operador aún no tenga GPS. Si la
  /// empresa no tiene ciudad configurada, o el usuario es de Soporte (sin
  /// empresa), simplemente no queda sesgo de ciudad.
  Future<void> _aplicarCiudadDeOperacion() async {
    final miEmpresa = await _miEmpresaService.obtenerMiEmpresa();
    GeocodingService.configurarUbicacionPorDefecto(
      miEmpresa?.latitudOperacion,
      miEmpresa?.longitudOperacion,
    );
  }

  /// Intenta iniciar sesión con correo y contraseña.
  /// Retorna true si el inicio de sesión fue exitoso.
  Future<bool> login(String correo, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    AuthResult? result;
    try {
      result = await _authService.login(correo, password);
    } on AuthException catch (e) {
      _cargando = false;
      _logueado = false;
      _usuario = null;
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
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
    await _aplicarCiudadDeOperacion();
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

  /// Cierra la sesión: borra el token y los datos del usuario del
  /// almacenamiento seguro y limpia el estado local.
  Future<void> logout() async {
    await ApiService.clearSession();
    _logueado = false;
    _usuario = null;
    // Evita que el sesgo de ciudad de esta empresa se filtre a la sesión de
    // otra si el siguiente usuario en loguearse es de una empresa distinta.
    GeocodingService.configurarUbicacionPorDefecto(null, null);

    notifyListeners();
  }
}
