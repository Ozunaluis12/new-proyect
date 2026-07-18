/// Modelo central de la app: representa una recogida de paquetes de un
/// cliente. El operador que la atiende cambia su [estado] (Pendiente ->
/// Recogida/Cancelada) y puede registrar el cobro del dinero asociado.
/// El operador "dueño" ([usuarioId]) y el responsable del dinero se
/// reasignan siempre a quien hace el cambio de estado, no a quien la creó.
class Recogida {
  final int id;
  final int clienteId;
  // Resuelto por el backend junto con la recogida, para no tener que
  // consultar aparte el cliente asociado.
  final String? clienteNombre;
  final String? clienteTelefono;
  // Puede venir nulo desde el backend (p. ej. recogida aún sin operador
  // asignado), por eso es nullable.
  final int? usuarioId;
  // Igual que clienteNombre: ya viene resuelto desde el backend.
  final String? usuarioNombre;
  final String estado;
  final int cantidadPaquetes;
  final String? observaciones;
  final List<String> evidencias;
  final bool dineroRecibido;
  final double? montoCobrado;
  final double? latitud; // Ubicación de la recogida
  final double? longitud; // Ubicación de la recogida
  final DateTime? fechaCreacion;
  // Horario límite acordado con el cliente para completar la recogida.
  // Opcional: si es null, la recogida no tiene urgencia por horario.
  final DateTime? fechaProgramada;
  // Momento en que efectivamente se completó (estado pasó a "Recogida").
  // Null mientras siga pendiente.
  final DateTime? fechaRecogida;

  /// Constructor que requiere todos los campos de una recogida.
  Recogida({
    required this.id,
    required this.clienteId,
    this.clienteNombre,
    this.clienteTelefono,
    this.usuarioId,
    this.usuarioNombre,
    required this.estado,
    required this.cantidadPaquetes,
    this.observaciones,
    required this.evidencias,
    this.dineroRecibido = false,
    this.montoCobrado,
    this.latitud,
    this.longitud,
    this.fechaCreacion,
    this.fechaProgramada,
    this.fechaRecogida,
  });

  /// True si tiene horario límite fijado y todavía no se completó ni canceló.
  bool get tieneHorarioActivo =>
      fechaProgramada != null &&
      estado.toLowerCase() != 'recogida' &&
      estado.toLowerCase() != 'cancelada';

  /// True si el horario límite ya pasó y la recogida sigue sin completarse.
  bool get horarioVencido =>
      tieneHorarioActivo && fechaProgramada!.isBefore(DateTime.now());

  /// True si falta poco para el horario límite (dentro de [umbral], 60 min
  /// por defecto) pero todavía no se venció.
  bool horarioProximoAVencer({Duration umbral = const Duration(minutes: 60)}) {
    if (!tieneHorarioActivo || horarioVencido) return false;
    return fechaProgramada!.difference(DateTime.now()) <= umbral;
  }

  /// Crea una instancia desde un JSON devuelto por el servidor.
  factory Recogida.fromJson(Map<String, dynamic> json) {
    return Recogida(
      id: json['id'],
      clienteId: json['clienteId'],
      clienteNombre: json['clienteNombre'],
      clienteTelefono: json['clienteTelefono'],
      usuarioId: json['usuarioId'],
      usuarioNombre: json['usuarioNombre'],
      estado: json['estado'],
      cantidadPaquetes: json['cantidadPaquetes'],
      observaciones: json['observaciones'],
      evidencias: List<String>.from(json['evidencias'] ?? []),
      dineroRecibido: json['dineroRecibido'] ?? false,
      montoCobrado: json['montoCobrado']?.toDouble(),
      latitud: json['latitud']?.toDouble(),
      longitud: json['longitud']?.toDouble(),
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'])
          : null,
      fechaProgramada: json['fechaProgramada'] != null
          ? DateTime.parse(json['fechaProgramada']).toLocal()
          : null,
      fechaRecogida: json['fechaRecogida'] != null
          ? DateTime.parse(json['fechaRecogida']).toLocal()
          : null,
    );
  }

  /// Convierte a JSON para usar en respuestas de la API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clienteId': clienteId,
      'usuarioId': usuarioId,
      'estado': estado,
      'cantidadPaquetes': cantidadPaquetes,
      'observaciones': observaciones,
      'evidencias': evidencias,
      'dineroRecibido': dineroRecibido,
      'montoCobrado': montoCobrado,
      'latitud': latitud,
      'longitud': longitud,
      'fechaCreacion': fechaCreacion?.toIso8601String(),
      'fechaProgramada': fechaProgramada?.toUtc().toIso8601String(),
      'fechaRecogida': fechaRecogida?.toUtc().toIso8601String(),
    };
  }

  /// Convierte a JSON para enviar al servidor (sin id).
  Map<String, dynamic> toRequestJson() {
    return {
      'clienteId': clienteId,
      'usuarioId': usuarioId,
      'estado': estado,
      'cantidadPaquetes': cantidadPaquetes,
      'observaciones': observaciones,
      'dineroRecibido': dineroRecibido,
      'montoCobrado': montoCobrado,
      'latitud': latitud,
      'longitud': longitud,
      'fechaProgramada': fechaProgramada?.toUtc().toIso8601String(),
    };
  }

  /// Obtiene un par [latitud, longitud] si ambas están disponibles,
  /// para usar directamente en el mapa (OpenStreetMap/Mapbox).
  List<double>? get coordenadas {
    if (latitud != null && longitud != null) {
      return [latitud!, longitud!];
    }
    return null;
  }
}
