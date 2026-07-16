/// Operador o subadministrador que puede tener caja pendiente por cerrar.
class OperadorDisponible {
  final int id;
  final String nombre;
  final String rol;

  OperadorDisponible({required this.id, required this.nombre, required this.rol});

  factory OperadorDisponible.fromJson(Map<String, dynamic> json) {
    return OperadorDisponible(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      rol: json['rol'] ?? '',
    );
  }
}

/// Un movimiento individual dentro de un resumen o un cierre de caja.
class IngresoDetalle {
  final int id;
  final String clienteNombre;
  final double monto;
  final String formaPago;
  final DateTime fechaIngreso;

  IngresoDetalle({
    required this.id,
    required this.clienteNombre,
    required this.monto,
    required this.formaPago,
    required this.fechaIngreso,
  });

  factory IngresoDetalle.fromJson(Map<String, dynamic> json) {
    return IngresoDetalle(
      id: json['id'],
      clienteNombre: json['clienteNombre'] ?? '',
      monto: (json['monto'] as num).toDouble(),
      formaPago: json['formaPago'] ?? '',
      fechaIngreso: DateTime.parse(json['fechaIngreso']),
    );
  }
}

/// Dinero pendiente por cerrar de un operador, con desglose y detalle.
class ResumenCaja {
  final int operadorId;
  final String operadorNombre;
  final double total;
  final double totalEfectivo;
  final double totalTransferencia;
  final int count;
  final List<IngresoDetalle> detalle;

  ResumenCaja({
    required this.operadorId,
    required this.operadorNombre,
    required this.total,
    required this.totalEfectivo,
    required this.totalTransferencia,
    required this.count,
    required this.detalle,
  });

  factory ResumenCaja.fromJson(Map<String, dynamic> json) {
    return ResumenCaja(
      operadorId: json['operadorId'],
      operadorNombre: json['operadorNombre'] ?? '',
      total: (json['total'] as num).toDouble(),
      totalEfectivo: (json['totalEfectivo'] as num).toDouble(),
      totalTransferencia: (json['totalTransferencia'] as num).toDouble(),
      count: json['count'] ?? 0,
      detalle: (json['detalle'] as List<dynamic>? ?? [])
          .map((item) => IngresoDetalle.fromJson(item))
          .toList(),
    );
  }
}

/// Un cierre de caja ya guardado (manual o automático).
class CierreCaja {
  final int id;
  final int operadorId;
  final String operadorNombre;
  final DateTime fecha;
  final double montoTotal;
  final double montoEfectivo;
  final double montoTransferencia;
  final String? observaciones;
  final bool generadoAutomaticamente;
  final int creadoPor;
  final DateTime fechaCreacion;
  final List<IngresoDetalle>? detalle;

  CierreCaja({
    required this.id,
    required this.operadorId,
    required this.operadorNombre,
    required this.fecha,
    required this.montoTotal,
    required this.montoEfectivo,
    required this.montoTransferencia,
    this.observaciones,
    required this.generadoAutomaticamente,
    required this.creadoPor,
    required this.fechaCreacion,
    this.detalle,
  });

  factory CierreCaja.fromJson(Map<String, dynamic> json) {
    return CierreCaja(
      id: json['id'],
      operadorId: json['operadorId'],
      operadorNombre: json['operadorNombre'] ?? '',
      fecha: DateTime.parse(json['fecha']),
      montoTotal: (json['montoTotal'] as num).toDouble(),
      montoEfectivo: (json['montoEfectivo'] as num).toDouble(),
      montoTransferencia: (json['montoTransferencia'] as num).toDouble(),
      observaciones: json['observaciones'],
      generadoAutomaticamente: json['generadoAutomaticamente'] ?? false,
      creadoPor: json['creadoPor'] ?? 0,
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      detalle: json['detalle'] == null
          ? null
          : (json['detalle'] as List<dynamic>)
              .map((item) => IngresoDetalle.fromJson(item))
              .toList(),
    );
  }
}
