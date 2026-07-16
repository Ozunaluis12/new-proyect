using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

/// <summary>Registra una evidencia ya subida a otro lugar, referenciándola solo por URL.</summary>
public record EvidenciaRequest(
    [Required] int RecogidaId,
    [Required] string FotoUrl,
    string Comentario);

/// <summary>
/// Variante de EvidenciaRequest usada cuando el archivo se envía directamente en el
/// request (multipart/form-data) en vez de ya estar alojado en una URL.
/// </summary>
public class EvidenciaUploadRequest
{
    [Required]
    public int RecogidaId { get; set; }

    public IFormFile? Foto { get; set; }

    public string? Comentario { get; set; }
}

/// <summary>Datos de una evidencia devueltos por la API.</summary>
public record EvidenciaResponse(
    int Id,
    int RecogidaId,
    string FotoUrl,
    string? Comentario,
    DateTime FechaCreacion);
