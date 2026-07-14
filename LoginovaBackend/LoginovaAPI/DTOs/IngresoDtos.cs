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
