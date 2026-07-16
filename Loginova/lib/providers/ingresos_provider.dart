import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../models/cierre_caja.dart';
import '../models/ingreso.dart';
import '../services/ingreso_service.dart';

/// Provider que gestiona el historial de dinero cobrado (ingresos) y el
/// cierre de caja: listar operadores con caja pendiente, ver el resumen
/// (desglose efectivo/transferencia), cerrar caja y consultar el historial
/// de cierres ya realizados.
class IngresosProvider extends ChangeNotifier {
  final IngresoService _service = IngresoService();

  List<Ingreso> _ingresos = [];
  bool _cargando = false;
  String? _error;

  List<Ingreso> get ingresos => List.unmodifiable(_ingresos);
  bool get cargando => _cargando;
  String? get error => _error;

  /// Carga el historial de ingresos (dinero cobrado), con filtros opcionales
  /// por cliente, operador y rango de fechas.
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

  /// Exporta los ingresos filtrados a un archivo CSV (bytes) para descarga.
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

  /// Lista los operadores/subadministradores que pueden tener caja abierta,
  /// para el selector de cierre de caja.
  Future<List<OperadorDisponible>> obtenerOperadoresDisponibles() async {
    return await _service.obtenerOperadoresDisponibles();
  }

  /// Obtiene el resumen de dinero pendiente por cerrar de un operador
  /// (con desglose por efectivo/transferencia y detalle de recogidas).
  Future<ResumenCaja> resumenCaja(int operadorId) async {
    return await _service.resumenCaja(operadorId);
  }

  /// Cierra la caja del operador: agrupa todo el dinero pendiente en un
  /// nuevo registro de cierre. El dinero y el operador quedan tomados de
  /// quien realiza el cierre (ver commit "El operador y el dinero de una
  /// recogida se toman de quien la completa").
  Future<CierreCaja> cerrarCaja(int operadorId, {String? observaciones}) async {
    return await _service.cerrarCaja(operadorId, observaciones: observaciones);
  }

  /// Obtiene el historial de cierres de caja ya realizados, con filtros
  /// opcionales por operador y rango de fechas.
  Future<List<CierreCaja>> obtenerHistorialCierres({
    int? operadorId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    return await _service.obtenerHistorialCierres(
      operadorId: operadorId,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  /// Obtiene el detalle completo de un cierre puntual, incluyendo los
  /// ingresos que quedaron agrupados en él.
  Future<CierreCaja> obtenerDetalleCierre(int id) async {
    return await _service.obtenerDetalleCierre(id);
  }
}
