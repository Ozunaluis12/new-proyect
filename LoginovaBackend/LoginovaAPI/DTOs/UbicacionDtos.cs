using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

public record UbicacionRequest(
    [Required] decimal Latitud,
    [Required] decimal Longitud,
    double PrecisionMetros,
    double? Velocidad,
    DateTime FechaRegistro);

