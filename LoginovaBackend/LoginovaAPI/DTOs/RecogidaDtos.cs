using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

public record RecogidaRequest(
    [Required] int ClienteId,
    int? UsuarioId,
    [Required] string Estado,
    [Range(0, int.MaxValue)] int CantidadPaquetes,
    string? Observaciones,
    decimal? Latitud,
    decimal? Longitud,
    bool DineroRecibido,
    decimal? MontoCobrado);

public class ActualizarEstadoRecogidaRequest
{
    [Required]
    public string Estado { get; set; } = string.Empty;

    public string? FotoUrl { get; set; }

    public string? Comentario { get; set; }

    public bool DineroRecibido { get; set; }

    public decimal? MontoCobrado { get; set; }

    public string? FormaPago { get; set; }

    public IFormFile? Foto { get; set; }
}

public record RecogidaResponse(
    int Id,
    int ClienteId,
    int? UsuarioId,
    string Estado,
    int CantidadPaquetes,
    string? Observaciones,
    List<string> Evidencias,
    decimal? Latitud,
    decimal? Longitud,
    bool DineroRecibido,
    decimal? MontoCobrado,
    DateTime? FechaCreacion);
