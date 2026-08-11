/// Un pago/renovación de membresía registrado para una empresa: a
/// diferencia del monto vigente actual en [Empresa], cada instancia aquí
/// es un registro histórico de un cobro puntual.
class PagoMembresia {
  final int id;
  final double monto;
  final String? cicloPago;
  final DateTime fechaPago;
  final DateTime? periodoDesde;
  final DateTime? periodoHasta;
  final String? notas;
  final String registradoPorNombre;

  PagoMembresia({
    required this.id,
    required this.monto,
    this.cicloPago,
    required this.fechaPago,
    this.periodoDesde,
    this.periodoHasta,
    this.notas,
    required this.registradoPorNombre,
  });

  factory PagoMembresia.fromJson(Map<String, dynamic> json) {
    return PagoMembresia(
      id: json['id'],
      monto: (json['monto'] as num).toDouble(),
      cicloPago: json['cicloPago'],
      fechaPago: DateTime.parse(json['fechaPago']).toLocal(),
      periodoDesde: json['periodoDesde'] != null
          ? DateTime.parse(json['periodoDesde']).toLocal()
          : null,
      periodoHasta: json['periodoHasta'] != null
          ? DateTime.parse(json['periodoHasta']).toLocal()
          : null,
      notas: json['notas'],
      registradoPorNombre: json['registradoPorNombre'] ?? 'Soporte',
    );
  }
}
