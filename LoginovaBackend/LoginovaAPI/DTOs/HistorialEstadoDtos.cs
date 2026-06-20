using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

public record HistorialEstadoRequest(
    [Required] int RecogidaId,
    string? EstadoAnterior,
    [Required] string EstadoNuevo,
    int? UsuarioId);
