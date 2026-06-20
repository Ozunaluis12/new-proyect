using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

public record RecogidaRequest(
    [Required] int ClienteId,
    int? UsuarioId,
    [Required] string Estado,
    [Range(0, int.MaxValue)] int CantidadPaquetes,
    string? Observaciones);

public record RecogidaResponse(
    int Id,
    int ClienteId,
    int? UsuarioId,
    string Estado,
    int CantidadPaquetes,
    string? Observaciones,
    List<string> Evidencias);
