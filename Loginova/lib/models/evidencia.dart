/// Modelo que representa una evidencia (foto) de una recogida.
class Evidencia {
  final int id;
  final int recogidaId;
  final String fotoUrl;
  final String comentario;

  /// Constructor que requiere todos los campos de una evidencia.
  Evidencia({
    required this.id,
    required this.recogidaId,
    required this.fotoUrl,
    required this.comentario,
  });

  /// Crea una instancia desde un JSON devuelto por el servidor.
  factory Evidencia.fromJson(Map<String, dynamic> json) {
    return Evidencia(
      id: json['id'],
      recogidaId: json['recogidaId'],
      fotoUrl: json['fotoUrl'],
      comentario: json['comentario'],
    );
  }

  /// Convierte a JSON para usar en respuestas de la API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recogidaId': recogidaId,
      'fotoUrl': fotoUrl,
      'comentario': comentario,
    };
  }
}
