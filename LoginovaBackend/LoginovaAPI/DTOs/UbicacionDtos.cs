using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

/// <summary>Reporte de posición geográfica enviado por la app de un operador (tracking en vivo).</summary>
public record UbicacionRequest(
    [Required] decimal Latitud,
    [Required] decimal Longitud,
    double PrecisionMetros,
    double? Velocidad,
    DateTime FechaRegistro);

/// <summary>Datos de una ubicación devueltos por la API.</summary>
public record UbicacionResponse(
    int Id,
    int UsuarioId,
    decimal Latitud,
    decimal Longitud,
    double PrecisionMetros,
    double? Velocidad,
    DateTime FechaRegistro);

