/// Una entrada de la bitácora de soporte de una empresa: registro fechado e
/// inmutable de una interacción, a diferencia del campo libre "Notas" de
/// [Empresa] (una sola nota editable, sin historial).
class NotaSoporte {
  final int id;
  final String contenido;
  final String creadoPorNombre;
  final DateTime fechaCreacion;

  NotaSoporte({
    required this.id,
    required this.contenido,
    required this.creadoPorNombre,
    required this.fechaCreacion,
  });

  factory NotaSoporte.fromJson(Map<String, dynamic> json) {
    return NotaSoporte(
      id: json['id'],
      contenido: json['contenido'] ?? '',
      creadoPorNombre: json['creadoPorNombre'] ?? 'Soporte',
      fechaCreacion: DateTime.parse(json['fechaCreacion']).toLocal(),
    );
  }
}
