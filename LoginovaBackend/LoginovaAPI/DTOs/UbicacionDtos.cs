using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

public record UbicacionRequest(
    [Required] int UsuarioId,
    [Required] decimal Latitud,
    [Required] decimal Longitud);
