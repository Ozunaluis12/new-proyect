/// Empresa cliente del sistema multi-tenant (tenant real, no un simple
/// registro de CRM): cada una es una organización que compró Loginova y
/// cuyos datos (recogidas, clientes, usuarios, etc.) están aislados del
/// resto de empresas en el mismo backend. Solo lo administra el rol Soporte.
class Empresa {
  final int id;
  final String nombreEmpresa;
  final String? nombreContacto;
  final String? telefonoContacto;
  final String? correoContacto;
  final DateTime fechaInicioMembresia;
  final DateTime fechaFinMembresia;
  final double? montoMembresia;
  final String? cicloPago;
  final String? notas;
  final bool activa;
  final DateTime? ultimoRecordatorioEnviado;
  final DateTime fechaCreacion;
  // Calculados por el backend: "Suspendida", "Vencida", "PorVencer" o
  // "Vigente", y los días restantes (negativo si ya venció). Se guardan tal
  // cual en vez de recalcularlos en el cliente para no duplicar la regla.
  final String estadoMembresia;
  final int diasParaVencimiento;

  Empresa({
    required this.id,
    required this.nombreEmpresa,
    this.nombreContacto,
    this.telefonoContacto,
    this.correoContacto,
    required this.fechaInicioMembresia,
    required this.fechaFinMembresia,
    this.montoMembresia,
    this.cicloPago,
    this.notas,
    this.activa = true,
    this.ultimoRecordatorioEnviado,
    required this.fechaCreacion,
    required this.estadoMembresia,
    required this.diasParaVencimiento,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'],
      nombreEmpresa: json['nombreEmpresa'],
      nombreContacto: json['nombreContacto'],
      telefonoContacto: json['telefonoContacto'],
      correoContacto: json['correoContacto'],
      fechaInicioMembresia: DateTime.parse(
        json['fechaInicioMembresia'],
      ).toLocal(),
      fechaFinMembresia: DateTime.parse(json['fechaFinMembresia']).toLocal(),
      montoMembresia: json['montoMembresia']?.toDouble(),
      cicloPago: json['cicloPago'],
      notas: json['notas'],
      activa: json['activa'] ?? true,
      ultimoRecordatorioEnviado: json['ultimoRecordatorioEnviado'] != null
          ? DateTime.parse(json['ultimoRecordatorioEnviado']).toLocal()
          : null,
      fechaCreacion: DateTime.parse(json['fechaCreacion']).toLocal(),
      estadoMembresia: json['estadoMembresia'] ?? 'Vigente',
      diasParaVencimiento: json['diasParaVencimiento'] ?? 0,
    );
  }

  /// Cuerpo para actualizar una empresa existente (PUT /api/empresas/{id}).
  /// No incluye "activa": eso se controla solo con los endpoints dedicados
  /// activar/suspender, nunca editando el resto de los datos.
  Map<String, dynamic> toUpdateRequestJson() {
    return {
      'nombreEmpresa': nombreEmpresa,
      'nombreContacto': nombreContacto,
      'telefonoContacto': telefonoContacto,
      'correoContacto': correoContacto,
      'fechaInicioMembresia': fechaInicioMembresia.toUtc().toIso8601String(),
      'fechaFinMembresia': fechaFinMembresia.toUtc().toIso8601String(),
      'montoMembresia': montoMembresia,
      'cicloPago': cicloPago,
      'notas': notas,
    };
  }
}
