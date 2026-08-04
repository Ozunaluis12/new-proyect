import 'package:flutter/material.dart';

import '../models/empresa_cliente.dart';
import '../services/empresa_cliente_service.dart';

/// Provider del CRM interno de empresas clientes (panel de soporte). El
/// listado ya viene ordenado por urgencia de vencimiento desde el backend.
class EmpresasClientesProvider extends ChangeNotifier {
  final EmpresaClienteService _service = EmpresaClienteService();

  List<EmpresaCliente> _empresas = [];
  bool _cargando = false;
  String? _error;

  List<EmpresaCliente> get empresas => List.unmodifiable(_empresas);
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

  Future<void> agregarEmpresa(EmpresaCliente empresa) async {
    await _service.crearEmpresa(empresa);
    await cargarEmpresas();
  }

  Future<void> actualizarEmpresa(int id, EmpresaCliente empresa) async {
    await _service.actualizarEmpresa(id, empresa);
    await cargarEmpresas();
  }

  Future<void> marcarRecordatorioEnviado(int id) async {
    await _service.marcarRecordatorioEnviado(id);
    await cargarEmpresas();
  }

  Future<void> eliminarEmpresa(int id) async {
    await _service.eliminarEmpresa(id);
    await cargarEmpresas();
  }
}
