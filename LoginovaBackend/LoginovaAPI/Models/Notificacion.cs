using System.ComponentModel.DataAnnotations.Schema;

namespace LoginovaAPI.Models;

/// <summary>
/// Modelo que representa una notificación push enviada a un usuario.
/// </summary>
[Table("notificaciones")]
public class Notificacion
{
    /// <summary>Identificador único de la notificación.</summary>
    [Column("id")]
    public int Id { get; set; }

    /// <summary>Identificador del usuario destinatario.</summary>
    [Column("usuario_id")]
    public int UsuarioId { get; set; }

    /// <summary>Relación: usuario destinatario.</summary>
    public Usuario? Usuario { get; set; }

    /// <summary>Token FCM del dispositivo del usuario.</summary>
    [Column("fcm_token")]
    public string FcmToken { get; set; } = string.Empty;

    /// <summary>Título de la notificación.</summary>
    [Column("titulo")]
    public string Titulo { get; set; } = string.Empty;

    /// <summary>Cuerpo/mensaje de la notificación.</summary>
    [Column("cuerpo")]
    public string Cuerpo { get; set; } = string.Empty;

    /// <summary>Tipo de notificación: recogida_asignada, cambio_estado, recordatorio, general.</summary>
    [Column("tipo")]
    public string Tipo { get; set; } = "general";

    /// <summary>Datos adicionales en formato JSON.</summary>
    [Column("datos_adicionales")]
    public string? DatosAdicionales { get; set; }

    /// <summary>ID de la recogida asociada (si aplica).</summary>
    [Column("recogida_id")]
    public int? RecogidaId { get; set; }

    /// <summary>Si la notificación fue enviada exitosamente.</summary>
    [Column("enviado")]
    public bool Enviado { get; set; } = false;

    /// <summary>Fecha en que se envió la notificación.</summary>
    [Column("fecha_envio")]
    public DateTime? FechaEnvio { get; set; }

    /// <summary>Fecha de creación del registro.</summary>
    [Column("fecha_creacion")]
    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    /// <summary>Si el usuario leyó/abrió la notificación.</summary>
    [Column("leido")]
    public bool Leido { get; set; } = false;

    /// <summary>Fecha en que se leyó la notificación.</summary>
    [Column("fecha_lectura")]
    public DateTime? FechaLectura { get; set; }
}
