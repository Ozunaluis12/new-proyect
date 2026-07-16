using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

/// <summary>Registra manualmente una entrada de historial de cambio de estado de una recogida.</summary>
public record HistorialEstadoRequest(
    [Required] int RecogidaId,
    string? EstadoAnterior,
    [Required] string EstadoNuevo,
    int? UsuarioId);
