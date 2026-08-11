/// Panorama rápido de actividad de una empresa para el Panel de Soporte:
/// cuánta gente y movimiento tiene, y cuándo fue la última vez que se usó
/// de verdad. Permite diagnosticar un caso sin pedirle capturas de
/// pantalla al cliente.
class ResumenSoporteEmpresa {
  final int totalUsuarios;
  final int totalClientes;
  final int totalRecogidas;
  final int recogidasPendientes;
  final int totalIngresos;
  final double montoTotalIngresos;
  final DateTime? ultimaRecogida;

  ResumenSoporteEmpresa({
    required this.totalUsuarios,
    required this.totalClientes,
    required this.totalRecogidas,
    required this.recogidasPendientes,
    required this.totalIngresos,
    required this.montoTotalIngresos,
    this.ultimaRecogida,
  });

  factory ResumenSoporteEmpresa.fromJson(Map<String, dynamic> json) {
    return ResumenSoporteEmpresa(
      totalUsuarios: json['totalUsuarios'] ?? 0,
      totalClientes: json['totalClientes'] ?? 0,
      totalRecogidas: json['totalRecogidas'] ?? 0,
      recogidasPendientes: json['recogidasPendientes'] ?? 0,
      totalIngresos: json['totalIngresos'] ?? 0,
      montoTotalIngresos: (json['montoTotalIngresos'] ?? 0).toDouble(),
      ultimaRecogida: json['ultimaRecogida'] != null
          ? DateTime.parse(json['ultimaRecogida']).toLocal()
          : null,
    );
  }
}
