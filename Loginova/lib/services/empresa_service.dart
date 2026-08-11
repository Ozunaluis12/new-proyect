import 'dart:convert';

import 'package:http/http.dart' as http;

import 'dart:typed_data';

import '../models/cliente.dart';
import '../models/dashboard_soporte.dart';
import '../models/empresa.dart';
import '../models/ingreso.dart';
import '../models/nota_soporte.dart';
import '../models/pago_membresia.dart';
import '../models/recogida.dart';
import '../models/resumen_soporte_empresa.dart';
import '../models/usuario.dart';
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

  /// Usuarios de una empresa específica, con sus permisos. Para que Soporte
  /// pueda investigar un caso sin depender de capturas de pantalla del cliente.
  Future<List<Usuario>> obtenerUsuariosDeEmpresa(int empresaId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/empresas/$empresaId/usuarios'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los usuarios de la empresa');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Usuario.fromJson(item)).toList();
  }

  /// Corrige los permisos de un usuario de una empresa específica (p. ej. un
  /// administrador que quedó bloqueado o un operador mal configurado).
  Future<void> actualizarPermisosUsuario({
    required int empresaId,
    required int usuarioId,
    required List<String> permisos,
  }) async {
    final response = await http.put(
      Uri.parse(
        '${ApiService.baseUrl}/empresas/$empresaId/usuarios/$usuarioId/permisos',
      ),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({'permisos': permisos}),
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudieron actualizar los permisos');
    }
  }

  /// Panorama rápido de actividad de una empresa (usuarios, clientes,
  /// recogidas, ingresos y última recogida) para diagnosticar un caso de
  /// soporte sin recorrer manualmente cada módulo.
  Future<ResumenSoporteEmpresa> obtenerResumenEmpresa(int empresaId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/empresas/$empresaId/resumen'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el resumen de la empresa');
    }

    return ResumenSoporteEmpresa.fromJson(jsonDecode(response.body));
  }

  /// Historial de auditoría de una empresa específica (quién cambió qué y cuándo).
  Future<List<Map<String, dynamic>>> obtenerAuditoriaEmpresa(int empresaId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/empresas/$empresaId/auditoria'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar la auditoría de la empresa');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.whereType<Map<String, dynamic>>().toList();
  }

  /// Restablece la contraseña de un usuario a una temporal generada al azar
  /// (p. ej. quedó bloqueado y no le llega el correo de recuperación).
  /// Devuelve la contraseña en claro, visible una sola vez.
  Future<String> restablecerPassword({
    required int empresaId,
    required int usuarioId,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/empresas/$empresaId/usuarios/$usuarioId/restablecer-password',
      ),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo restablecer la contraseña');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['passwordTemporal'] as String;
  }

  /// Panorama agregado de todas las empresas (para el resumen del Panel de
  /// Soporte): cuántas activas/suspendidas/por vencer/vencidas, ingreso
  /// mensual estimado y empresas sin actividad reciente.
  Future<DashboardSoporte> obtenerDashboard() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/empresas/dashboard'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el panorama de empresas');
    }

    return DashboardSoporte.fromJson(jsonDecode(response.body));
  }

  /// Exporta el listado completo de empresas a CSV.
  Future<Uint8List> exportarEmpresasCsv() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/empresas/export'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo exportar el listado de empresas');
    }

    return response.bodyBytes;
  }

  /// Bitácora de soporte de una empresa: historial fechado e inmutable de
  /// interacciones (a diferencia del campo libre "Notas" de [Empresa]).
  Future<List<NotaSoporte>> obtenerNotasSoporte(int empresaId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/empresas/$empresaId/notas-soporte'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las notas de soporte');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => NotaSoporte.fromJson(item)).toList();
  }

  /// Agrega una entrada a la bitácora de soporte de una empresa.
  Future<void> crearNotaSoporte({
    required int empresaId,
    required String contenido,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/empresas/$empresaId/notas-soporte'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({'contenido': contenido}),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo guardar la nota de soporte');
    }
  }

  /// Clientes reales de una empresa (no solo el conteo), para ver/diagnosticar un caso puntual.
  Future<List<Cliente>> obtenerClientesDeEmpresa(int empresaId, {String? busqueda}) async {
    final uri = Uri.parse('${ApiService.baseUrl}/empresas/$empresaId/clientes').replace(
      queryParameters: (busqueda != null && busqueda.trim().isNotEmpty)
          ? {'busqueda': busqueda.trim()}
          : null,
    );
    final response = await http.get(uri, headers: ApiService.jsonHeaders);

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los clientes de la empresa');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Cliente.fromJson(item)).toList();
  }

  /// Recogidas reales de una empresa (no solo el conteo), más recientes primero.
  Future<List<Recogida>> obtenerRecogidasDeEmpresa(int empresaId, {String? busqueda}) async {
    final uri = Uri.parse('${ApiService.baseUrl}/empresas/$empresaId/recogidas').replace(
      queryParameters: (busqueda != null && busqueda.trim().isNotEmpty)
          ? {'busqueda': busqueda.trim()}
          : null,
    );
    final response = await http.get(uri, headers: ApiService.jsonHeaders);

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las recogidas de la empresa');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Recogida.fromJson(item)).toList();
  }

  /// Ingresos reales de una empresa (no solo el conteo/total), más recientes primero.
  Future<List<Ingreso>> obtenerIngresosDeEmpresa(int empresaId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/empresas/$empresaId/ingresos'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los ingresos de la empresa');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Ingreso.fromJson(item)).toList();
  }

  /// Encuentra a qué empresa pertenece un correo (para cuando un cliente
  /// escribe a Soporte dando solo su correo). Null si no existe.
  Future<Map<String, dynamic>?> buscarUsuarioPorCorreo(String correo) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/empresas/buscar-usuario',
    ).replace(queryParameters: {'correo': correo.trim()});
    final response = await http.get(uri, headers: ApiService.jsonHeaders);

    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw Exception('No se pudo buscar el usuario');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Activa o desactiva el acceso de un usuario puntual, sin afectar al resto de la empresa.
  Future<void> cambiarEstadoUsuario({
    required int empresaId,
    required int usuarioId,
    required bool activo,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/empresas/$empresaId/usuarios/$usuarioId/estado'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({'activo': activo}),
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudo cambiar el estado del usuario');
    }
  }

  /// Historial de pagos/renovaciones de membresía de una empresa.
  Future<List<PagoMembresia>> obtenerPagosMembresia(int empresaId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/empresas/$empresaId/pagos-membresia'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los pagos de membresía');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => PagoMembresia.fromJson(item)).toList();
  }

  /// Registra un nuevo pago/renovación de membresía para una empresa.
  Future<void> crearPagoMembresia({
    required int empresaId,
    required double monto,
    String? cicloPago,
    DateTime? periodoDesde,
    DateTime? periodoHasta,
    String? notas,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/empresas/$empresaId/pagos-membresia'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({
        'monto': monto,
        'cicloPago': cicloPago,
        'periodoDesde': periodoDesde?.toUtc().toIso8601String(),
        'periodoHasta': periodoHasta?.toUtc().toIso8601String(),
        'notas': notas,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo registrar el pago de membresía');
    }
  }
}
