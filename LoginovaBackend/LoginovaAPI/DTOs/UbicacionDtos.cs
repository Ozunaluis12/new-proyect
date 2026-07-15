using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

public record UbicacionRequest(
    [Required] decimal Latitud,
    [Required] decimal Longitud,
    double PrecisionMetros,
    double? Velocidad,
    DateTime FechaRegistro);

public record UbicacionResponse(
    int Id,
    int UsuarioId,
    decimal Latitud,
    decimal Longitud,
    double PrecisionMetros,
    double? Velocidad,
    DateTime FechaRegistro);

