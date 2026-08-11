/// Modelo que representa un usuario autenticado en la aplicación.
class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String rol;
  final List<String> permisos;
  final bool activo;

  /// Constructor que requiere todos los campos.
  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.permisos,
    this.activo = true,
  });

  /// Crea una instancia de Usuario desde un JSON devuelto por el servidor.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'],
      correo: json['correo'],
      rol: json['rol'] ?? '',
      permisos: List<String>.from(json['permisos'] ?? const []),
      // Default true: sesiones guardadas antes de que este campo existiera
      // no lo tendrán en su JSON local, y no deben tratarse como inactivas.
      activo: json['activo'] ?? true,
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
      'activo': activo,
    };
  }

  /// Chequeo de permisos del lado del cliente: solo sirve para
  /// mostrar/ocultar elementos de la UI. La autorización real de cada
  /// acción siempre la valida el backend, así que esto nunca debe usarse
  /// como único mecanismo de seguridad.
  /// El Administrador siempre tiene todos los permisos implícitamente.
  bool tienePermiso(String permiso) {
    if (rol.toLowerCase() == 'administrador') {
      return true;
    }

    return permisos.any((item) => item.toLowerCase() == permiso.toLowerCase());
  }
}
