/// Modelo que representa un usuario autenticado en la aplicación.
class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String rol;

  /// Constructor que requiere todos los campos.
  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  /// Crea una instancia de Usuario desde un JSON devuelto por el servidor.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'],
      correo: json['correo'],
      rol: json['rol'] ?? '',
    );
  }

  /// Convierte el usuario a un mapa JSON para enviar al servidor.
  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre, 'correo': correo, 'rol': rol};
  }
}
