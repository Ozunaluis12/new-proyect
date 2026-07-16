/// Modelo que representa una recogida de paquetes en el sistema.
class Recogida {
  final int id;
  final int clienteId;
  final String? clienteNombre;
  final String? clienteTelefono;
  final int? usuarioId;
  final String estado;
  final int cantidadPaquetes;
  final String? observaciones;
  final List<String> evidencias;
  final bool dineroRecibido;
  final double? montoCobrado;
  final double? latitud; // Ubicación de la recogida
  final double? longitud; // Ubicación de la recogida
  final DateTime? fechaCreacion;

  /// Constructor que requiere todos los campos de una recogida.
  Recogida({
    required this.id,
    required this.clienteId,
    this.clienteNombre,
    this.clienteTelefono,
    this.usuarioId,
    required this.estado,
    required this.cantidadPaquetes,
    this.observaciones,
    required this.evidencias,
    this.dineroRecibido = false,
    this.montoCobrado,
    this.latitud,
    this.longitud,
    this.fechaCreacion,
  });

  /// Crea una instancia desde un JSON devuelto por el servidor.
  factory Recogida.fromJson(Map<String, dynamic> json) {
    return Recogida(
      id: json['id'],
      clienteId: json['clienteId'],
      clienteNombre: json['clienteNombre'],
      clienteTelefono: json['clienteTelefono'],
      usuarioId: json['usuarioId'],
      estado: json['estado'],
      cantidadPaquetes: json['cantidadPaquetes'],
      observaciones: json['observaciones'],
      evidencias: List<String>.from(json['evidencias'] ?? []),
      dineroRecibido: json['dineroRecibido'] ?? false,
      montoCobrado: json['montoCobrado']?.toDouble(),
      latitud: json['latitud']?.toDouble(),
      longitud: json['longitud']?.toDouble(),
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'])
          : null,
    );
  }

  /// Convierte a JSON para usar en respuestas de la API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clienteId': clienteId,
      'usuarioId': usuarioId,
      'estado': estado,
      'cantidadPaquetes': cantidadPaquetes,
      'observaciones': observaciones,
      'evidencias': evidencias,
      'dineroRecibido': dineroRecibido,
      'montoCobrado': montoCobrado,
      'latitud': latitud,
      'longitud': longitud,
      'fechaCreacion': fechaCreacion?.toIso8601String(),
    };
  }

  /// Convierte a JSON para enviar al servidor (sin id).
  Map<String, dynamic> toRequestJson() {
    return {
      'clienteId': clienteId,
      'usuarioId': usuarioId,
      'estado': estado,
      'cantidadPaquetes': cantidadPaquetes,
      'observaciones': observaciones,
      'dineroRecibido': dineroRecibido,
      'montoCobrado': montoCobrado,
      'latitud': latitud,
      'longitud': longitud,
    };
  }

  /// Obtiene un par [latitud, longitud] si ambas están disponibles
  List<double>? get coordenadas {
    if (latitud != null && longitud != null) {
      return [latitud!, longitud!];
    }
    return null;
  }
}
