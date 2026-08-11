import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Plantillas de mensaje de WhatsApp para el recordatorio de vencimiento,
/// editables por Soporte sin tocar código.
class ConfiguracionSoporteService {
  Future<Map<String, String>> obtener() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/configuracionsoporte'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar la configuración de Soporte');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'plantillaRecordatorioVigente': data['plantillaRecordatorioVigente'] ?? '',
      'plantillaRecordatorioVencida': data['plantillaRecordatorioVencida'] ?? '',
    };
  }

  Future<void> actualizar({
    required String plantillaVigente,
    required String plantillaVencida,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/configuracionsoporte'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode({
        'plantillaRecordatorioVigente': plantillaVigente,
        'plantillaRecordatorioVencida': plantillaVencida,
      }),
    );

    if (response.statusCode != 204) {
      throw Exception('No se pudo guardar la configuración');
    }
  }
}
