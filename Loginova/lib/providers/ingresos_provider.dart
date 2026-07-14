import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../models/ingreso.dart';
import '../services/ingreso_service.dart';

class IngresosProvider extends ChangeNotifier {
  final IngresoService _service = IngresoService();

  List<Ingreso> _ingresos = [];
  bool _cargando = false;
  String? _error;

  List<Ingreso> get ingresos => List.unmodifiable(_ingresos);
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargarIngresos({
    String? cliente,
    String? operador,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _ingresos = await _service.obtenerIngresos(
        cliente: cliente,
        operador: operador,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<Uint8List> exportarIngresosCsv({
    String? cliente,
    String? operador,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    return await _service.exportarIngresosCsv(
      cliente: cliente,
      operador: operador,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  Future<Map<String, dynamic>> resumenCaja(
    int operadorId,
    DateTime fecha,
  ) async {
    return await _service.resumenCaja(operadorId, fecha);
  }

  Future<void> cerrarCaja(
    int operadorId,
    DateTime fecha, {
    String? observaciones,
  }) async {
    return await _service.cerrarCaja(
      operadorId,
      fecha,
      observaciones: observaciones,
    );
  }
}
