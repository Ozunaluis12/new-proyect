import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cliente.dart';
import 'api_service.dart';

/// Servicio que gestiona la comunicación con el backend para operaciones CRUD de clientes.
class ClienteService {
  /// Obtiene la lista completa de clientes del servidor.
  Future<List<Cliente>> obtenerClientes() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/clientes'),
      headers: ApiService.jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los clientes');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Cliente.fromJson(item)).toList();
  }

  /// Crea un nuevo cliente en el servidor y retorna el cliente creado con ID.
  Future<Cliente> crearCliente(Cliente cliente) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/clientes'),
      headers: ApiService.jsonHeaders,
      body: jsonEncode(cliente.toRequestJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo crear el cliente');
    }

    return Cliente.fromJson(jsonDecode(response.body));
  }
}
