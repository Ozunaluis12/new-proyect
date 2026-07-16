namespace LoginovaAPI.DTOs;

/// <summary>
/// Datos de un ingreso (cobro) devueltos por la API. ResponsableUsuarioId/Nombre
/// identifican a quien realmente cobró (el que hizo el cambio de estado), no a
/// quien creó la recogida originalmente.
/// </summary>
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

/// <summary>Operador que puede recibir una recogida asignada (para selects/listas en el frontend).</summary>
public record OperadorDisponibleResponse(int Id, string Nombre, string Rol);

/// <summary>Fila resumida de un ingreso, usada dentro de listados de caja (resumen o cierre).</summary>
public record IngresoDetalleResponse(
    int Id,
    string ClienteNombre,
    decimal Monto,
    string FormaPago,
    DateTime FechaIngreso);

/// <summary>
/// Resumen de la caja pendiente (aún no cerrada) de un operador: totales por forma
/// de pago y el detalle de cada ingreso incluido, previo a ejecutar un cierre.
/// </summary>
public record ResumenCajaResponse(
    int OperadorId,
    string OperadorNombre,
    decimal Total,
    decimal TotalEfectivo,
    decimal TotalTransferencia,
    int Count,
    List<IngresoDetalleResponse> Detalle);

/// <summary>Solicitud para ejecutar manualmente el cierre de caja de un operador (crea un CierreCaja).</summary>
public record CerrarCajaRequest(int OperadorId, string? Observaciones);

/// <summary>
/// Datos de un cierre de caja ya realizado. GeneradoAutomaticamente/CreadoPor
/// indican si lo generó un administrador manualmente o el cron automático nocturno
/// (CreadoPor == 0 en ese caso).
/// </summary>
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
