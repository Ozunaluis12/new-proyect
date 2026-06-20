/// Modelo que representa un cliente en el sistema.
class Cliente {
  final int id;
  final String nombre;
  final String telefono;
  final String direccion;
  final String ciudad;

  /// Constructor que requiere todos los campos de un cliente.
  Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.direccion,
    required this.ciudad,
  });

  /// Crea una instancia desde un JSON devuelto por el servidor.
  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      direccion: json['direccion'],
      ciudad: json['ciudad'] ?? '',
    );
  }

  /// Convierte a JSON para usar en respuestas de la API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'ciudad': ciudad,
    };
  }

  /// Convierte a JSON para enviar al servidor (sin id).
  Map<String, dynamic> toRequestJson() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'ciudad': ciudad,
    };
  }
}
