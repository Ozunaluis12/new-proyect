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

  static const List<String> all = [
    crearRecogidas,
    editarRecogidas,
    cambiarEstadoRecogidas,
    subirEvidencias,
    registrarIngresos,
    verIngresos,
    verUsuarios,
    gestionarUsuarios,
    verAuditoria,
    gestionarNotificaciones,
    verUbicaciones,
    gestionarUbicaciones,
  ];

  static const Map<String, String> labels = {
    crearRecogidas: 'Crear recogidas',
    editarRecogidas: 'Editar recogidas',
    cambiarEstadoRecogidas: 'Cambiar estado',
    subirEvidencias: 'Subir evidencias',
    registrarIngresos: 'Registrar ingresos del cliente',
    verIngresos: 'Ver historial de ingresos',
    verUsuarios: 'Ver usuarios',
    gestionarUsuarios: 'Gestionar usuarios',
    verAuditoria: 'Ver auditoría',
    gestionarNotificaciones: 'Gestionar notificaciones',
    verUbicaciones: 'Ver ubicaciones',
    gestionarUbicaciones: 'Gestionar ubicaciones',
  };
}
