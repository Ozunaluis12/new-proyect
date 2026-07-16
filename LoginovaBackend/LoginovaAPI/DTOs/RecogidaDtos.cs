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

    /// <summary>
    /// Cantidad real de paquetes, contada por el operador al recoger. Es
    /// opcional porque no todos los cambios de estado implican un conteo
    /// (por ejemplo, cancelar no requiere actualizarla).
    /// </summary>
    [Range(0, int.MaxValue)]
    public int? CantidadPaquetes { get; set; }

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
    string? ClienteNombre,
    string? ClienteTelefono,
    int? UsuarioId,
    string? UsuarioNombre,
    string Estado,
    int CantidadPaquetes,
    string? Observaciones,
    List<string> Evidencias,
    decimal? Latitud,
    decimal? Longitud,
    bool DineroRecibido,
    decimal? MontoCobrado,
    DateTime? FechaCreacion);
