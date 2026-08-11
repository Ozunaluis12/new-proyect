/// Panorama agregado de todas las empresas para el Panel de Soporte.
class DashboardSoporte {
  final int totalEmpresas;
  final int empresasActivas;
  final int empresasSuspendidas;
  final int empresasPorVencer;
  final int empresasVencidas;
  final double ingresoMensualEstimado;
  final int empresasSinActividadReciente;

  DashboardSoporte({
    required this.totalEmpresas,
    required this.empresasActivas,
    required this.empresasSuspendidas,
    required this.empresasPorVencer,
    required this.empresasVencidas,
    required this.ingresoMensualEstimado,
    required this.empresasSinActividadReciente,
  });

  factory DashboardSoporte.fromJson(Map<String, dynamic> json) {
    return DashboardSoporte(
      totalEmpresas: json['totalEmpresas'] ?? 0,
      empresasActivas: json['empresasActivas'] ?? 0,
      empresasSuspendidas: json['empresasSuspendidas'] ?? 0,
      empresasPorVencer: json['empresasPorVencer'] ?? 0,
      empresasVencidas: json['empresasVencidas'] ?? 0,
      ingresoMensualEstimado: (json['ingresoMensualEstimado'] ?? 0).toDouble(),
      empresasSinActividadReciente: json['empresasSinActividadReciente'] ?? 0,
    );
  }
}
