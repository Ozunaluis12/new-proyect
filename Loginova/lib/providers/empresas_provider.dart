import 'package:flutter/material.dart';

import '../models/empresa.dart';
import '../services/empresa_service.dart';

/// Provider del Panel de Soporte. El listado ya viene ordenado por urgencia
/// de vencimiento desde el backend.
class EmpresasProvider extends ChangeNotifier {
  final EmpresaService _service = EmpresaService();

  List<Empresa> _empresas = [];
  bool _cargando = false;
  String? _error;

  List<Empresa> get empresas => List.unmodifiable(_empresas);
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargarEmpresas() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _empresas = await _service.obtenerEmpresas();
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> crearEmpresa({
    required Empresa empresa,
    required String adminNombre,
    required String adminCorreo,
    required String adminPassword,
  }) async {
    await _service.crearEmpresa(
      empresa: empresa,
      adminNombre: adminNombre,
      adminCorreo: adminCorreo,
      adminPassword: adminPassword,
    );
    await cargarEmpresas();
  }

  Future<void> actualizarEmpresa(int id, Empresa empresa) async {
    await _service.actualizarEmpresa(id, empresa);
    await cargarEmpresas();
  }

  Future<void> marcarRecordatorioEnviado(int id) async {
    await _service.marcarRecordatorioEnviado(id);
    await cargarEmpresas();
  }

  Future<void> activarEmpresa(int id) async {
    await _service.activarEmpresa(id);
    await cargarEmpresas();
  }

  Future<void> suspenderEmpresa(int id) async {
    await _service.suspenderEmpresa(id);
    await cargarEmpresas();
  }
}
