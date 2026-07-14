class Ingreso {
  final int id;
  final int recogidaId;
  final int clienteId;
  final String clienteNombre;
  final int responsableUsuarioId;
  final String responsableNombre;
  final double monto;
  final String formaPago;
  final DateTime fechaIngreso;

  Ingreso({
    required this.id,
    required this.recogidaId,
    required this.clienteId,
    required this.clienteNombre,
    required this.responsableUsuarioId,
    required this.responsableNombre,
    required this.monto,
    required this.formaPago,
    required this.fechaIngreso,
  });

  factory Ingreso.fromJson(Map<String, dynamic> json) {
    return Ingreso(
      id: json['id'],
      recogidaId: json['recogidaId'],
      clienteId: json['clienteId'],
      clienteNombre: json['clienteNombre'] ?? '',
      responsableUsuarioId: json['responsableUsuarioId'],
      responsableNombre: json['responsableNombre'] ?? '',
      monto: (json['monto'] as num).toDouble(),
      formaPago: json['formaPago'] ?? '',
      fechaIngreso: DateTime.parse(json['fechaIngreso']),
    );
  }
}
