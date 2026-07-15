using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

public record EvidenciaRequest(
    [Required] int RecogidaId,
    [Required] string FotoUrl,
    string Comentario);

public class EvidenciaUploadRequest
{
    [Required]
    public int RecogidaId { get; set; }

    public IFormFile? Foto { get; set; }

    public string? Comentario { get; set; }
}

public record EvidenciaResponse(
    int Id,
    int RecogidaId,
    string FotoUrl,
    string? Comentario,
    DateTime FechaCreacion);
