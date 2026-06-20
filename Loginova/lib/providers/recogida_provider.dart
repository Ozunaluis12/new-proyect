import 'package:flutter/material.dart';

import '../models/recogida.dart';
import '../services/recogida_service.dart';

/// Provider que gestiona el estado de las recogidas y su comunicación con el backend.
class RecogidaProvider extends ChangeNotifier {
  final RecogidaService _service = RecogidaService();
  final List<Recogida> _recogidas = [];
  bool _cargando = false;
  String? _error;

  List<Recogida> get recogidas => List.unmodifiable(_recogidas);
  bool get cargando => _cargando;
  String? get error => _error;

  /// Carga todas las recogidas del servidor.
  Future<void> cargarRecogidas() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.obtenerRecogidas();
      _recogidas
        ..clear()
        ..addAll(data);
    } catch (_) {
      _error = 'No se pudieron cargar las recogidas';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Agrega una nueva recogida al servidor y actualiza el estado.
  Future<void> agregarRecogida(Recogida recogida) async {
    final creada = await _service.crearRecogida(recogida);
    _recogidas.add(creada);
    notifyListeners();
  }

  /// Actualiza una recogida existente en el servidor.
  Future<void> actualizarRecogida(Recogida recogida) async {
    await _service.actualizarRecogida(recogida);
    final index = _recogidas.indexWhere((item) => item.id == recogida.id);
    if (index != -1) {
      _recogidas[index] = recogida;
    }
    notifyListeners();
  }

  /// Elimina una recogida del servidor por su identificador.
  Future<void> eliminarRecogida(int id) async {
    await _service.eliminarRecogida(id);
    _recogidas.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Agrega una recogida al estado local sin sincronizar con el servidor.
  void agregarRecogidaLocal(Recogida recogida) {
    _recogidas.add(recogida);
    notifyListeners();
  }
}
