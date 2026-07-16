/// Catálogo de permisos granulares que pueden asignarse a cualquier rol
/// (Administrador, Subadministrador, Operador, Cliente). Los valores
/// string deben coincidir exactamente con los permisos definidos en el
/// backend (ASP.NET Core); si se agrega/renombra un permiso aquí, hay
/// que reflejarlo también del lado del servidor.
class PermissionConstants {
  static const String crearRecogidas = 'crear_recogidas';
  static const String editarRecogidas = 'editar_recogidas';
  static const String cambiarEstadoRecogidas = 'cambiar_estado_recogidas';
  static const String subirEvidencias = 'subir_evidencias';
  static const String registrarIngresos = 'registrar_ingresos';
  static const String verIngresos = 'ver_ingresos';
  static const String verUsuarios = 'ver_usuarios';
  static const String gestionarUsuarios = 'gestionar_usuarios';
  static const String verAuditoria = 'ver_auditoria';
  static const String gestionarNotificaciones = 'gestionar_notificaciones';
  static const String verUbicaciones = 'ver_ubicaciones';
  static const String gestionarUbicaciones = 'gestionar_ubicaciones';
  static const String verClientes = 'ver_clientes';
  static const String gestionarClientes = 'gestionar_clientes';
  static const String cerrarCaja = 'cerrar_caja';

  /// Lista de todos los permisos existentes, usada para poblar el
  /// selector de permisos al crear/editar un rol o usuario.
  static const List<String> all = [
    crearRecogidas,
    editarRecogidas,
    cambiarEstadoRecogidas,
    subirEvidencias,
    registrarIngresos,
    verIngresos,
    cerrarCaja,
    verUsuarios,
    gestionarUsuarios,
    verAuditoria,
    gestionarNotificaciones,
    verUbicaciones,
    gestionarUbicaciones,
    verClientes,
    gestionarClientes,
  ];

  /// Etiquetas legibles en español para mostrar cada permiso en la UI
  /// (los valores de [all] son claves internas en snake_case).
  static const Map<String, String> labels = {
    crearRecogidas: 'Crear recogidas',
    editarRecogidas: 'Editar recogidas',
    cambiarEstadoRecogidas: 'Cambiar estado',
    subirEvidencias: 'Subir evidencias',
    registrarIngresos: 'Registrar ingresos del cliente',
    verIngresos: 'Ver historial de ingresos',
    cerrarCaja: 'Cerrar caja (propia o de otros)',
    verUsuarios: 'Ver usuarios',
    gestionarUsuarios: 'Gestionar usuarios',
    verAuditoria: 'Ver auditoría',
    gestionarNotificaciones: 'Gestionar notificaciones',
    verUbicaciones: 'Ver ubicaciones',
    gestionarUbicaciones: 'Gestionar ubicaciones',
    verClientes: 'Ver clientes',
    gestionarClientes: 'Gestionar clientes',
  };
}
