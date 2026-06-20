using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

public record EvidenciaRequest(
    [Required] int RecogidaId,
    [Required] string FotoUrl,
    string Comentario);
