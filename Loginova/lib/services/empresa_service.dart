import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/empresa.dart';
import 'api_service.dart';

/// Servicio que gestiona la comunicación con el backend para el Panel de
/// Soporte: alta de empresas (junto con su primer Administrador), edición
/// de membresía y activación/suspensión. Exclusivo del rol Soporte.
class EmpresaService {
  Future<List<Empresa>> obtenerEmpresas() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/empresas'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las empresas');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Empresa.fromJson(item)).toList();
  }

  /// Crea una empresa nueva junto con su primer Administrador en un solo paso.
  Future<Empresa> crearEmpresa({
    required Empresa empresa,
    required String adminNombre,
    required String adminCorreo,
    required String adminPassword,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/empresas'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({
        ...empresa.toUpdateRequestJson(),
        'adminNombre': adminNombre,
        'adminCorreo': adminCorreo,
        'adminPassword': adminPassword,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo crear la empresa: ${response.body}');
    }

    return Empresa.fromJson(jsonDecode(response.body));
  }

  Future<void> actualizarEmpresa(int id, Empresa empresa) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/empresas/$id'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode(empresa.toUpdateRequestJson()),
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudo actualizar la empresa');
    }
  }

  Future<void> marcarRecordatorioEnviado(int id) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/empresas/$id/recordatorio-enviado'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo marcar el recordatorio como enviado');
    }
  }

  /// Reactiva la empresa: sus usuarios recuperan acceso de inmediato.
  Future<void> activarEmpresa(int id) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/empresas/$id/activar'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo activar la empresa');
    }
  }

  /// Suspende la empresa: TODOS sus usuarios pierden acceso de inmediato,
  /// sin importar el vencimiento de membresía.
  Future<void> suspenderEmpresa(int id) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/empresas/$id/suspender'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo suspender la empresa');
    }
  }
}
