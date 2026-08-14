import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Datos de la propia empresa del usuario autenticado, incluida su ciudad de
/// operación ya geocodificada (si Soporte la configuró), usada para sesgar
/// el buscador de direcciones mientras no hay GPS real disponible.
class MiEmpresa {
  final int id;
  final String nombreEmpresa;
  final String? ciudadOperacion;
  final double? latitudOperacion;
  final double? longitudOperacion;

  MiEmpresa({
    required this.id,
    required this.nombreEmpresa,
    this.ciudadOperacion,
    this.latitudOperacion,
    this.longitudOperacion,
  });

  factory MiEmpresa.fromJson(Map<String, dynamic> json) {
    return MiEmpresa(
      id: json['id'],
      nombreEmpresa: json['nombreEmpresa'],
      ciudadOperacion: json['ciudadOperacion'],
      latitudOperacion: json['latitudOperacion']?.toDouble(),
      longitudOperacion: json['longitudOperacion']?.toDouble(),
    );
  }
}

/// Consulta los datos de la propia empresa del usuario autenticado: su
/// nombre (para mostrarlo en el botón de "Contactar Soporte") y su ciudad de
/// operación (para sesgar el buscador de direcciones). Devuelve null si no
/// se pudo obtener (p. ej. sin conexión, o el usuario es de Soporte y no
/// pertenece a ninguna empresa): quien la use debe seguir funcionando igual
/// sin estos datos.
class MiEmpresaService {
  Future<MiEmpresa?> obtenerMiEmpresa() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/miempresa'),
        headers: ApiService.jsonHeaders,
      );

      if (response.statusCode != 200) {
        return null;
      }

      return MiEmpresa.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  Future<String?> obtenerNombreEmpresa() async {
    return (await obtenerMiEmpresa())?.nombreEmpresa;
  }
}
