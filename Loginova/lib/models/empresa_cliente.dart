/// Empresa que compró Loginova (CRM interno del vendedor, no un cliente de
/// recogidas). Cada una corre su propia instalación independiente; este
/// modelo solo existe en la instalación del vendedor para llevar control de
/// membresías, contacto y seguimiento.
class EmpresaCliente {
  final int id;
  final String nombreEmpresa;
  final String? nombreContacto;
  final String? telefonoContacto;
  final String? correoContacto;
  final String? urlInstalacion;
  final DateTime fechaInicioMembresia;
  final DateTime fechaFinMembresia;
  final double? montoMembresia;
  final String? cicloPago;
  final String? notas;
  final bool activa;
  final DateTime? ultimoRecordatorioEnviado;
  final DateTime fechaCreacion;
  // Calculados por el backend: "Vencida", "PorVencer" o "Vigente", y los
  // días restantes (negativo si ya venció). Se guardan tal cual en vez de
  // recalcularlos en el cliente para no duplicar la regla de negocio.
  final String estadoMembresia;
  final int diasParaVencimiento;

  EmpresaCliente({
    required this.id,
    required this.nombreEmpresa,
    this.nombreContacto,
    this.telefonoContacto,
    this.correoContacto,
    this.urlInstalacion,
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

  factory EmpresaCliente.fromJson(Map<String, dynamic> json) {
    return EmpresaCliente(
      id: json['id'],
      nombreEmpresa: json['nombreEmpresa'],
      nombreContacto: json['nombreContacto'],
      telefonoContacto: json['telefonoContacto'],
      correoContacto: json['correoContacto'],
      urlInstalacion: json['urlInstalacion'],
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

  Map<String, dynamic> toRequestJson() {
    return {
      'nombreEmpresa': nombreEmpresa,
      'nombreContacto': nombreContacto,
      'telefonoContacto': telefonoContacto,
      'correoContacto': correoContacto,
      'urlInstalacion': urlInstalacion,
      'fechaInicioMembresia': fechaInicioMembresia.toUtc().toIso8601String(),
      'fechaFinMembresia': fechaFinMembresia.toUtc().toIso8601String(),
      'montoMembresia': montoMembresia,
      'cicloPago': cicloPago,
      'notas': notas,
      'activa': activa,
    };
  }
}
