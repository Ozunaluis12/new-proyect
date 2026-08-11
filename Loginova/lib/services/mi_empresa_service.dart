import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Consulta el nombre de la propia empresa del usuario autenticado. Se usa
/// para mostrarlo en el mensaje del botón "Contactar Soporte". Devuelve
/// null si no se pudo obtener (p. ej. sin conexión): el botón igual debe
/// funcionar solo con el nombre del usuario.
class MiEmpresaService {
  Future<String?> obtenerNombreEmpresa() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/miempresa'),
        headers: ApiService.jsonHeaders,
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['nombreEmpresa'] as String?;
    } catch (_) {
      return null;
    }
  }
}
