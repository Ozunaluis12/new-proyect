namespace LoginovaAPI.DTOs;

public record IngresoResponse(
    int Id,
    int RecogidaId,
    int ClienteId,
    string ClienteNombre,
    int ResponsableUsuarioId,
    string ResponsableNombre,
    decimal Monto,
    string FormaPago,
    DateTime FechaIngreso);

public record OperadorDisponibleResponse(int Id, string Nombre, string Rol);

public record IngresoDetalleResponse(
    int Id,
    string ClienteNombre,
    decimal Monto,
    string FormaPago,
    DateTime FechaIngreso);

public record ResumenCajaResponse(
    int OperadorId,
    string OperadorNombre,
    decimal Total,
    decimal TotalEfectivo,
    decimal TotalTransferencia,
    int Count,
    List<IngresoDetalleResponse> Detalle);

public record CerrarCajaRequest(int OperadorId, string? Observaciones);

public record CierreCajaResponse(
    int Id,
    int OperadorId,
    string OperadorNombre,
    DateTime Fecha,
    decimal MontoTotal,
    decimal MontoEfectivo,
    decimal MontoTransferencia,
    string? Observaciones,
    bool GeneradoAutomaticamente,
    int CreadoPor,
    DateTime FechaCreacion,
    List<IngresoDetalleResponse>? Detalle = null);
