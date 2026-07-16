/// Modelo que representa un ingreso de dinero cobrado en una recogida
/// (efectivo o transferencia). El [responsableUsuarioId] es el operador
/// que queda a cargo de ese dinero hasta que se le haga un cierre de
/// caja; se reasigna al operador que hace el cambio de estado que generó
/// el cobro, no necesariamente al creador original de la recogida.
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

  /// Constructor que requiere todos los campos de un ingreso.
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

  /// Crea una instancia desde un JSON devuelto por el servidor.
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
