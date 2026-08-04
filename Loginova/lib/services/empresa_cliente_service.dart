import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/empresa_cliente.dart';
import 'api_service.dart';

/// Servicio que gestiona la comunicación con el backend para el CRM interno
/// de empresas clientes (solo accesible por el rol Administrador).
class EmpresaClienteService {
  Future<List<EmpresaCliente>> obtenerEmpresas() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/empresasclientes'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las empresas clientes');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => EmpresaCliente.fromJson(item)).toList();
  }

  Future<EmpresaCliente> crearEmpresa(EmpresaCliente empresa) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/empresasclientes'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode(empresa.toRequestJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo crear la empresa cliente');
    }

    return EmpresaCliente.fromJson(jsonDecode(response.body));
  }

  Future<void> actualizarEmpresa(int id, EmpresaCliente empresa) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/empresasclientes/$id'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode(empresa.toRequestJson()),
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudo actualizar la empresa cliente');
    }
  }

  Future<void> marcarRecordatorioEnviado(int id) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/empresasclientes/$id/recordatorio-enviado'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo marcar el recordatorio como enviado');
    }
  }

  Future<void> eliminarEmpresa(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/empresasclientes/$id'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudo eliminar la empresa cliente');
    }
  }
}
