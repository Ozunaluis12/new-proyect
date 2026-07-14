/// Modelo que representa un usuario autenticado en la aplicación.
class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String rol;
  final List<String> permisos;

  /// Constructor que requiere todos los campos.
  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.permisos,
  });

  /// Crea una instancia de Usuario desde un JSON devuelto por el servidor.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'],
      correo: json['correo'],
      rol: json['rol'] ?? '',
      permisos: List<String>.from(json['permisos'] ?? const []),
    );
  }

  /// Convierte el usuario a un mapa JSON para enviar al servidor.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'permisos': permisos,
    };
  }

  bool tienePermiso(String permiso) {
    if (rol.toLowerCase() == 'administrador') {
      return true;
    }

    return permisos.any((item) => item.toLowerCase() == permiso.toLowerCase());
  }
}
