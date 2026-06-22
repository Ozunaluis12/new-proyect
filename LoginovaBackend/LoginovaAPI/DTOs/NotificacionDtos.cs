using System.ComponentModel.DataAnnotations;

namespace LoginovaAPI.DTOs;

/// <summary>
/// DTO para recibir el token FCM desde el cliente.
/// </summary>
public record FCMTokenRequest(
    [Required] string FcmToken);

/// <summary>
/// DTO para enviar notificaciones.
/// </summary>
public record NotificacionRequest(
    [Required] int UsuarioId,
    [Required] string Titulo,
    [Required] string Cuerpo,
    string Tipo = "general",
    int? RecogidaId = null,
    Dictionary<string, string>? DatosAdicionales = null);

/// <summary>
/// DTO de respuesta de notificación.
/// </summary>
public record NotificacionResponse(
    int Id,
    int UsuarioId,
    string Titulo,
    string Cuerpo,
    string Tipo,
    bool Enviado,
    bool Leido,
    DateTime FechaCreacion,
    DateTime? FechaEnvio,
    DateTime? FechaLectura);
